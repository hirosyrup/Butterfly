//
//  PreferencesUserVoiceprintViewController.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/04/28.
//

import Cocoa
import AVFoundation
import Hydra

protocol PreferencesUserVoiceprintViewControllerDelegate: class {
    func didUploadVoiceprint(vc: PreferencesUserVoiceprintViewController, data: PreferencesRepository.UserData)
}

class PreferencesUserVoiceprintViewController: NSViewController, AudioSystemDelegate {
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var levelMeterContainer: NSView!
    private weak var levelMeter: StatementLevelMeter!
    private let audioSystem = AudioSystem.shared
    private var audioFile: AudioFile?
    private var timer: Timer?
    private var isRecording = false
    private var userData: PreferencesRepository.UserData!
    private let outputFormat = AudioConverter.voiceprintOutputFormat
    
    weak var delegate: PreferencesUserVoiceprintViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        levelMeter = StatementLevelMeter.createFromNib(owner: nil)
        levelMeter.frame = levelMeterContainer.bounds
        levelMeter.updateThreshold(threshold: -15.0)
        levelMeterContainer.addSubview(levelMeter)
        
        audioSystem.delegate = self
        
        initButton()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        audioSystem.start()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        audioSystem.stop()
        audioSystem.delegate = nil
    }
    
    private func initButton() {
        cancelButton.isHidden = false
        startButton.isEnabled = true
        startButton.title = userData?.voicePrintName == nil ? "Start" : "Update"
    }
    
    private func clearTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startCountDown() {
        cancelButton.isHidden = true
        startButton.isEnabled = false
        var count = 20
        startButton.title = "\(count)"
        isRecording = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (_timer) in
            count -= 1
            if count == 0 {
                let saveUrl = self.audioFile!.saveUrl
                self.audioFile = nil
                self.endCountDown(saveUrl: saveUrl)
                self.clearTimer()
            } else {
                self.startButton.title = "\(count)"
            }
        })
    }
    
    private func endCountDown(saveUrl: URL) {
        isRecording = false
        startButton.isEnabled = false
        startButton.title = "Uploading..."
        async({ _ -> PreferencesRepository.UserData in
            let storage = VoiceprintStorage()
            if let currentFileName = self.userData?.voicePrintName {
                try? await(storage.delete(fileName: currentFileName))
            }
            let fileName = saveUrl.lastPathComponent
            try await(storage.upload(dataUrl: saveUrl, fileName: fileName))
            return try await(self.saveVoiceprintName(name: fileName))
        }).then({ userData in
            self.userData = userData
            self.delegate?.didUploadVoiceprint(vc: self, data: userData)
            self.dismiss(self)
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to upload the voiceprint data. \(error.localizedDescription)").runModal()
        }
    }
    
    private func saveVoiceprintName(name: String) -> Promise<PreferencesRepository.UserData> {
        return Promise<PreferencesRepository.UserData>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> PreferencesRepository.UserData in
                var newUserData = self.userData!
                newUserData.voicePrintName = name
                return try await(PreferencesRepository.User().update(userData: newUserData))
            }).then({ userData in
                resolve(userData)
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    func setupData(data: PreferencesRepository.UserData) {
        userData = data
    }
    
    func audioEngineStartError(obj: AudioSystem, error: Error) {
        clearTimer()
        initButton()
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start the audio system. \(error.localizedDescription)").runModal()
    }
    
    func notifyRenderBuffer(obj: AudioSystem, buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        levelMeter.setRms(rms: Double(Rms.calculate(buffer: buffer)))
        if isRecording {
            if let newBuffer = try? AudioConverter.convert(inputBuffer: buffer, format: AudioConverter.voiceprintProcessingFormat) {
                try? audioFile?.write(buffer: newBuffer)
            }
        }
    }
    
    @IBAction func pushStartButton(_ sender: Any) {
        let fileName = "\(UUID().uuidString).wav"
        let localUrl = AudioLocalUrl.createVoiceprintDirectoryUrl()
        let saveUrl = localUrl.appendingPathComponent("\(fileName)")
        audioFile = AudioFile(saveUrl: saveUrl, format: outputFormat)
        startCountDown()
    }
    
    @IBAction func pushCancelButton(_ sender: Any) {
        dismiss(self)
    }
}
