//
//  RecognitionRequest.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import Speech

protocol RecognitionRequestDelegate: class {
    func failedToRequest(request: RecognitionRequest, error: Error)
    func didUpdateStatement(request: RecognitionRequest, statement: String)
    func didEndStatement(request: RecognitionRequest, statement: String)
}

enum RecognitionRequestError: Error {
    case unableToCreateRequest
}

extension RecognitionRequestError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unableToCreateRequest: return "Unable to create a SFSpeechAudioBufferRecognitionRequest object"
        }
    }
}

class RecognitionRequest {
    enum State {
        case processing
        case ending
        case didEnd
    }
    
    let id: String
    private var recognitionTask: SFSpeechRecognitionTask!
    private let recognitionRequest: SFSpeechAudioBufferRecognitionRequest
    weak var delegate: RecognitionRequestDelegate?
    private var statement = ""
    private var state = State.processing
    private var endTimer: Timer?
    private let endingInterval = TimeInterval(1)
    
    init(id: String, speechRecognizer: SFSpeechRecognizer) {
        self.id = id
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if self.state != .didEnd {
                self.recognize(result: result, error: error)
            }
        }
    }
    
    private func recognize(result: SFSpeechRecognitionResult?, error: Error?) {
        if error != nil {
            delegate?.failedToRequest(request: self, error: error!)
            return
        }
        
        if let _result = result {
            statement = _result.bestTranscription.formattedString
            if _result.isFinal {
                notifyDidEnd()
            } else {
                delegate?.didUpdateStatement(request: self, statement: statement)
            }
        }
    }
    
    private func setEndTimerIfNeeded() {
        if state == .ending {
            endTimer = Timer.scheduledTimer(withTimeInterval: endingInterval, repeats: false, block: { (_) in
                self.notifyDidEnd()
                self.endTimer = nil
            })
        }
    }
    
    private func notifyDidEnd() {
        if state == .ending {
            state = .didEnd
            delegate?.didEndStatement(request: self, statement: statement)
        }
    }
    
    func append(buffer: AVAudioPCMBuffer) {
        if state != .didEnd {
            recognitionRequest.append(buffer)
        }
    }
    
    func endAudio() {
        state = .ending
        recognitionRequest.endAudio()
        setEndTimerIfNeeded()
    }
}