//
//  SpeechRecognizerAmiVoice.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/12.
//

import Foundation
import AVFoundation
import SwiftyBeaver

class SpeechRecognizerAmiVoice: SpeechRecognizer,
                                ObserveBreakInStatementsDelegate,
                                RecognitionRequestAmiVoiceDelegate {
    static let shared = SpeechRecognizerAmiVoice()
    
    var apiKey = ""
    var apiUrlString = ""
    private let observeBreakInStatements = ObserveBreakInStatements(bufferSize: AudioBufferSize.bufferSize)
    private var recognitionRequests = [RecognitionRequestAmiVoice]()
    private var currentRecognitionRequest: RecognitionRequestAmiVoice?
    
    weak var delegate: SpeechRecognizerDelegate?
    
    init() {
        self.observeBreakInStatements.delegate = self
    }
    
    func setRmsThreshold(threshold: Float) {
        observeBreakInStatements.rmsThreshold = threshold
    }
    
    func append(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        observeBreakInStatements.checkBreakInStatements(buffer: buffer, when: when)
        recognitionRequests.forEach { $0.append(buffer: buffer) }
    }
    
    func setDelegate(delegate: SpeechRecognizerDelegate?) {
        self.delegate = delegate
    }
    
    func didChangeSpeekingState(obj: ObserveBreakInStatements, isSpeeking: Bool, previousBuffers: [AVAudioPCMBuffer]) {
        if isSpeeking {
            let newRecognitionRequest = RecognitionRequestAmiVoice(id: UUID().uuidString, apiKey: apiKey, apiUrlString: apiUrlString)
            newRecognitionRequest.delegate = self
            currentRecognitionRequest = newRecognitionRequest
            recognitionRequests.append(newRecognitionRequest)
            previousBuffers.forEach { newRecognitionRequest.append(buffer: $0) }
            delegate?.didStartNewStatement(recognizer: self, id: newRecognitionRequest.id)
        } else {
            currentRecognitionRequest?.endAudio()
            currentRecognitionRequest = nil
        }
    }
    
    func failedToRequest(request: RecognitionRequestAmiVoice, error: Error) {
        SwiftyBeaver.self.error(error)
    }
    
    func didUpdateStatement(request: RecognitionRequestAmiVoice, statement: String) {
        delegate?.didUpdateStatement(recognizer: self, id: request.id, statement: statement)
    }
    
    func didEndStatement(request: RecognitionRequestAmiVoice, statement: String) {
        if let index = recognitionRequests.firstIndex(where: { $0 === request }) {
            recognitionRequests.remove(at: index)
        }
        delegate?.didEndStatement(recognizer: self, id: request.id, statement: statement)
    }
}
