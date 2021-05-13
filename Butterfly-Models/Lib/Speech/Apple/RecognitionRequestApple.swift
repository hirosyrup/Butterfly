//
//  RecognitionRequestApple.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import Speech

protocol RecognitionRequestAppleDelegate: class {
    func failedToRequest(request: RecognitionRequestApple, error: Error)
    func didUpdateStatement(request: RecognitionRequestApple, statement: String, speakerId: String?)
    func didEndStatement(request: RecognitionRequestApple, statement: String, speakerId: String?)
}

class RecognitionRequestApple {
    enum State {
        case processing
        case ending
        case didEnd
    }
    
    let id: String
    private var recognitionTask: SFSpeechRecognitionTask!
    private let recognitionRequest: SFSpeechAudioBufferRecognitionRequest
    weak var delegate: RecognitionRequestAppleDelegate?
    private var statement = ""
    private var state = State.processing
    private var endTimer: Timer?
    private let updateInterval = TimeInterval(1)
    private var previousNotifyUpdateDate = Date()
    private let endingInterval = TimeInterval(1)
    var currentSpeakerId: String?
    
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
                notifyUpdate()
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
            delegate?.didEndStatement(request: self, statement: statement, speakerId: currentSpeakerId)
        }
    }
    
    private func notifyUpdate() {
        if Date().timeIntervalSince1970 - previousNotifyUpdateDate.timeIntervalSince1970 > updateInterval {
            delegate?.didUpdateStatement(request: self, statement: statement, speakerId: currentSpeakerId)
            previousNotifyUpdateDate = Date()
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
