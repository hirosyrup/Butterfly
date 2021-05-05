//
//  SpeakerRecognizer.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/01.
//

import Foundation
import SoundAnalysis
import SwiftyBeaver

protocol SpeakerRecognizerDelegate: class {
    func didChangeSpeaker(recognizer: SpeakerRecognizer, speakerUserId: String?)
}

class SpeakerRecognizer: NSObject, SNResultsObserving {
    weak var delegate: SpeakerRecognizerDelegate?
    private let compileModelFileUrl: URL
    private let streamAnalyzer: SNAudioStreamAnalyzer
    private var currentSpeakerUserId: String?
    private var isStart = false
    
    init(compileModelFileUrl: URL, format: AVAudioFormat) {
        self.compileModelFileUrl = compileModelFileUrl
        self.streamAnalyzer = SNAudioStreamAnalyzer(format: format)
    }
    
    func start() throws {
        if isStart { return }
        isStart = true
        let model = try MLModel(contentsOf: compileModelFileUrl)
        let request = try SNClassifySoundRequest(mlModel: model)
        try streamAnalyzer.add(request, withObserver: self)
    }
    
    func stop() {
        streamAnalyzer.removeAllRequests()
        isStart = false
    }
    
    func resetSpeaker() {
        currentSpeakerUserId = nil
    }
    
    func analyze(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        guard isStart == true else { return}
        streamAnalyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
    }
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }
        
        guard currentSpeakerUserId != classification.identifier else { return }
        
        if classification.confidence >= 0.95 {
            currentSpeakerUserId = classification.identifier
        } else {
            currentSpeakerUserId = nil
        }
        
        delegate?.didChangeSpeaker(recognizer: self, speakerUserId: currentSpeakerUserId)
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        SwiftyBeaver.self.error(error)
    }
    
    func requestDidComplete(_ request: SNRequest) {
    }
}
