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
    private var currentSpeakerId: String?
    
    weak var delegate: SpeechRecognizerDelegate?
    
    override init() {
        super.init()
        self.observeBreakInStatements.delegate = self
    }
    
    private func startNewStatement(speechRecognizer: SFSpeechRecognizer, previousBuffers: [AVAudioPCMBuffer]) {
        let newRecognitionRequest = RecognitionRequestApple(id: UUID().uuidString, speechRecognizer: speechRecognizer)
        newRecognitionRequest.delegate = self
        newRecognitionRequest.currentSpeakerId = currentSpeakerId
        currentRecognitionRequest = newRecognitionRequest
        recognitionRequests.append(newRecognitionRequest)
        previousBuffers.forEach { newRecognitionRequest.append(buffer: $0) }
        delegate?.didStartNewStatement(recognizer: self, id: newRecognitionRequest.id, speakerId: newRecognitionRequest.currentSpeakerId)
    }
    
    private func endStatement() {
        currentRecognitionRequest?.endAudio()
        currentRecognitionRequest = nil
    }
    
    func setupRecognizer(languageIdentifier: String) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageIdentifier))
        speechRecognizer?.delegate = self
    }
    
    func setRmsThreshold(threshold: Float) {
        observeBreakInStatements.rmsThreshold = threshold
    }
    
    func append(buffer: AVAudioPCMBuffer, when: AVAudioTime, speakerId: String?){
        observeBreakInStatements.checkBreakInStatements(buffer: buffer, when: when)
        recognitionRequests.forEach { $0.append(buffer: buffer) }
        currentRecognitionRequest?.currentSpeakerId = speakerId
        currentSpeakerId = speakerId
    }
    
    func setDelegate(delegate: SpeechRecognizerDelegate?) {
        self.delegate = delegate
    }
    
    func executeForceLineBreak() {
        guard let _speechRecognizer = speechRecognizer else { return }
        endStatement()
        startNewStatement(speechRecognizer: _speechRecognizer, previousBuffers: [])
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        delegate?.didChangeAvailability(recognizer: self)
    }
    
    func didChangeSpeekingState(obj: ObserveBreakInStatements, isSpeeking: Bool, previousBuffers: [AVAudioPCMBuffer]) {
        guard let _speechRecognizer = speechRecognizer else { return }
        if isSpeeking {
            startNewStatement(speechRecognizer: _speechRecognizer, previousBuffers: previousBuffers)
        } else {
            endStatement()
        }
        delegate?.didChangeSpeekingState(recognizer: self, isSpeeking: isSpeeking)
    }
    
    func failedToRequest(request: RecognitionRequestApple, error: Error) {
        SwiftyBeaver.self.error(error)
    }
    
    func didUpdateStatement(request: RecognitionRequestApple, statement: String, speakerId: String?) {
        delegate?.didUpdateStatement(recognizer: self, id: request.id, statement: statement, speakerId: speakerId)
    }
    
    func didEndStatement(request: RecognitionRequestApple, statement: String, speakerId: String?) {
        if let index = recognitionRequests.firstIndex(where: { $0 === request }) {
            recognitionRequests.remove(at: index)
        }
        delegate?.didEndStatement(recognizer: self, id: request.id, statement: statement, speakerId: speakerId)
    }
}
