//
//  SpeechRecognizer.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import Speech
import SwiftyBeaver

class SpeechRecognizerApple: NSObject,
                             SpeechRecognizer,
                             SFSpeechRecognizerDelegate,
                             ObserveBreakInStatementsDelegate,
                             RecognitionRequestAppleDelegate {
    static let shared = SpeechRecognizerApple()
    
    let speechRecognizer: SFSpeechRecognizer
    private let observeBreakInStatements = ObserveBreakInStatements(bufferSize: AudioBufferSize.bufferSize)
    private var recognitionRequests = [RecognitionRequestApple]()
    private var currentRecognitionRequest: RecognitionRequestApple?
    
    weak var delegate: SpeechRecognizerDelegate?
    
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))!
        super.init()
        self.speechRecognizer.delegate = self
        self.observeBreakInStatements.delegate = self
    }
    
    func setRmsThreshold(threshold: Float) {
        observeBreakInStatements.rmsThreshold = threshold
    }
    
    func append(buffer: AVAudioPCMBuffer, when: AVAudioTime){
        observeBreakInStatements.checkBreakInStatements(buffer: buffer, when: when)
        recognitionRequests.forEach { $0.append(buffer: buffer) }
    }
    
    func setDelegate(delegate: SpeechRecognizerDelegate?) {
        self.delegate = delegate
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        delegate?.didChangeAvailability(recognizer: self)
    }
    
    func didChangeSpeekingState(obj: ObserveBreakInStatements, isSpeeking: Bool, previousBuffers: [AVAudioPCMBuffer]) {
        if isSpeeking {
            let newRecognitionRequest = RecognitionRequestApple(id: UUID().uuidString, speechRecognizer: speechRecognizer)
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
    
    func failedToRequest(request: RecognitionRequestApple, error: Error) {
        SwiftyBeaver.self.error(error)
    }
    
    func didUpdateStatement(request: RecognitionRequestApple, statement: String) {
        delegate?.didUpdateStatement(recognizer: self, id: request.id, statement: statement)
    }
    
    func didEndStatement(request: RecognitionRequestApple, statement: String) {
        if let index = recognitionRequests.firstIndex(where: { $0 === request }) {
            recognitionRequests.remove(at: index)
        }
        delegate?.didEndStatement(recognizer: self, id: request.id, statement: statement)
    }
}
