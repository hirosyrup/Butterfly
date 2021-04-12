//
//  SpeechRecognizerAmiVoice.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/12.
//

import Foundation
import AVFoundation

class SpeechRecognizerAmiVoice: SpeechRecognizer,
                                ObserveBreakInStatementsDelegate {
    static let shared = SpeechRecognizerAmiVoice()
    
    private let observeBreakInStatements = ObserveBreakInStatements(bufferSize: AudioBufferSize.bufferSize)
    private var recognitionRequests = [RecognitionRequestApple]()
    private var currentRecognitionRequest: RecognitionRequestApple?
    
    init() {
        self.observeBreakInStatements.delegate = self
    }
    
    func setRmsThreshold(threshold: Float) {
        observeBreakInStatements.rmsThreshold = threshold
    }
    
    func append(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        
    }
    
    func didChangeSpeekingState(obj: ObserveBreakInStatements, isSpeeking: Bool, previousBuffers: [AVAudioPCMBuffer]) {
        
    }
    
}
