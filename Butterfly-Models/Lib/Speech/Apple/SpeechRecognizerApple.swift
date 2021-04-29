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
    
    private var speechRecognizer: SFSpeechRecognizer?
    private let observeBreakInStatements = ObserveBreakInStatements()
    private var recognitionRequests = [RecognitionRequestApple]()
    private var currentRecognitionRequest: RecognitionRequestApple?
    
    weak var delegate: SpeechRecognizerDelegate?
    
    override init() {
        super.init()
        self.observeBreakInStatements.delegate = self
    }
    
    func setupRecognizer(languageIdentifier: String) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageIdentifier))
        speechRecognizer?.delegate = self
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
        guard let _speechRecognizer = speechRecognizer else { return }
        if isSpeeking {
            let newRecognitionRequest = RecognitionRequestApple(id: UUID().uuidString, speechRecognizer: _speechRecognizer)
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
