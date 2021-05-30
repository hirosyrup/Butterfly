//
//  AudioSystem.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/29.
//

import Foundation
import AVFoundation
import SwiftyBeaver

protocol AudioSystemDelegate: class {
    func audioEngineStartError(obj: AudioSystem, error: Error)
    func notifyRenderBuffer(obj: AudioSystem, buffer: AVAudioPCMBuffer, when: AVAudioTime)
}

class AudioSystem: NSObject {
    static let shared = AudioSystem()
    
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioNode
    private let bufferSize: UInt32
    var isRunning: Bool {
        get {
            return audioEngine.isRunning
        }
    }
    var inputFormat: AVAudioFormat {
        get {
            return inputNode.outputFormat(forBus: 0)
        }
    }
    
    weak var delegate: AudioSystemDelegate?
    
    override init() {
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
        
        self.bufferSize = AudioBufferSize.bufferSize
        super.init()
    }
    
    func setup() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            SwiftyBeaver.self.error(error)
        }
        #endif
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: nil) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            DispatchQueue.main.async {
                self.delegate?.notifyRenderBuffer(obj: self, buffer: buffer, when: when)
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
            self.delegate?.audioEngineStartError(obj: self, error: error)
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
}
