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
    private let observeBreakInStatements = ObserveBreakInStatements(bufferSize: AudioBufferSize.bufferSize)
    private var recognitionRequests = [RecognitionRequest]()
    private var currentRecognitionRequest: RecognitionRequest?
    
    weak var delegate: SpeechRecognizerDelegate?
    
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))!
        super.init()
        self.speechRecognizer.delegate = self
        self.observeBreakInStatements.delegate = self
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                self.authStatus = authStatus
            }
        }
    }
    
    func append(buffer: AVAudioPCMBuffer, when: AVAudioTime){
        observeBreakInStatements.checkBreakInStatements(buffer: buffer, when: when)
        recognitionRequests.forEach { $0.append(buffer: buffer) }
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
