//
//  SpeechRecognizer.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import Speech

protocol SpeechRecognizerDelegate: class {
    func didChangeAvailability(recognizer: SpeechRecognizer)
    func audioEngineStartError(recognizer: SpeechRecognizer, error: Error)
    func didNotCreateRecognitionRequest(recognizer: SpeechRecognizer, error: Error)
    func didStartNewStatement(recognizer: SpeechRecognizer, id: String)
    func didUpdateStatement(recognizer: SpeechRecognizer, id: String, statement: String)
    func didEndStatement(recognizer: SpeechRecognizer, id: String, statement: String)
}

class SpeechRecognizer: NSObject,
                        SFSpeechRecognizerDelegate,
                        ObserveBreakInStatementsDelegate,
                        RecognitionRequestDelegate {
    static let shared = SpeechRecognizer()
    
    let speechRecognizer: SFSpeechRecognizer
    private(set) var authStatus = SFSpeechRecognizerAuthorizationStatus.notDetermined
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioNode
    private let observeBreakInStatements = ObserveBreakInStatements(bufferSize: 1024)
    private var recognitionRequests = [RecognitionRequest]()
    private var currentRecognitionRequest: RecognitionRequest?
    var isRunning: Bool {
        get {
            return audioEngine.isRunning
        }
    }
    
    weak var delegate: SpeechRecognizerDelegate?
    
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))!
        
        // Test
//        let input = AVAudioPlayerNode()
//        let file = try! AVAudioFile(forReading: Bundle.main.url(forResource: "test", withExtension: "m4a")!)
//        audioEngine.attach(input)
//        input.scheduleFile(file, at: nil)
//        let recordingFormat = input.outputFormat(forBus: 0)
//        audioEngine.connect(input, to: audioEngine.mainMixerNode, format: recordingFormat)
//        self.inputNode = input
        
        // Production
        self.inputNode = audioEngine.inputNode
        
        super.init()
        self.speechRecognizer.delegate = self
        self.observeBreakInStatements.delegate = self
        self.setup()
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                self.authStatus = authStatus
            }
        }
    }
    
    private func setup() {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
        
        // Test
        //let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Production
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: observeBreakInStatements.bufferSize, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            DispatchQueue.main.async {
                self.observeBreakInStatements.checkBreakInStatements(buffer: buffer, when: when)
                self.recognitionRequests.forEach { $0.append(buffer: buffer) }
            }
        }
        
        audioEngine.prepare()
    }
    
    func start() {
        do {
            if !audioEngine.isRunning {
                try audioEngine.start()
                // Test
                //(inputNode as! AVAudioPlayerNode).play()
            }
        } catch {
            self.delegate?.audioEngineStartError(recognizer: self, error: error)
        }
    }
    
    func pause() {
        if audioEngine.isRunning {
            audioEngine.pause()
        }
    }
    
    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        delegate?.didChangeAvailability(recognizer: self)
    }
    
    func didChangeSpeekingState(obj: ObserveBreakInStatements, isSpeeking: Bool, previousBuffers: [AVAudioPCMBuffer]) {
        if isSpeeking {
            let newRecognitionRequest = RecognitionRequest(id: UUID().uuidString, speechRecognizer: speechRecognizer)
            newRecognitionRequest.delegate = self
            currentRecognitionRequest = newRecognitionRequest
            recognitionRequests.append(newRecognitionRequest)
            previousBuffers.forEach { newRecognitionRequest.append(buffer: $0) }
            delegate?.didStartNewStatement(recognizer: self, id: newRecognitionRequest.id)
            print("start speaking")
        } else {
            currentRecognitionRequest?.endAudio()
            currentRecognitionRequest = nil
            print("end speaking")
        }
    }
    
    func failedToRequest(request: RecognitionRequest, error: Error) {
        print("\(error.localizedDescription)")
    }
    
    func didUpdateStatement(request: RecognitionRequest, statement: String) {
        delegate?.didUpdateStatement(recognizer: self, id: request.id, statement: statement)
    }
    
    func didEndStatement(request: RecognitionRequest, statement: String) {
        if let index = recognitionRequests.firstIndex(where: { $0 === request }) {
            recognitionRequests.remove(at: index)
        }
        delegate?.didEndStatement(recognizer: self, id: request.id, statement: statement)
    }
}
