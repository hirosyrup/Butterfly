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
    private let checkCount = 2
    private var checkedCount = 0
    private var candidateSpeakerUserId: String?
    private let analysisQueue = DispatchQueue(label: "com.apple.AnalysisQueue")
    
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
        checkedCount = 0
    }
    
    func analyze(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        guard isStart == true else { return}
        analysisQueue.async {
            self.streamAnalyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
        }
    }
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first else { return }
        guard classification.confidence > 0.98 else {
            return
        }
        if candidateSpeakerUserId != classification.identifier {
            candidateSpeakerUserId = classification.identifier
            checkedCount = 0
            return
        } else {
            if checkedCount < checkCount {
                checkedCount += 1
                return
            }
            guard currentSpeakerUserId != candidateSpeakerUserId else { return }
            
            currentSpeakerUserId = candidateSpeakerUserId
            delegate?.didChangeSpeaker(recognizer: self, speakerUserId: currentSpeakerUserId)
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        SwiftyBeaver.self.error(error)
    }
    
    func requestDidComplete(_ request: SNRequest) {
    }
}
