//
//  ObserveBreakInStatements.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import AVFoundation

protocol ObserveBreakInStatementsDelegate: class {
    func didChangeSpeekingState(obj: ObserveBreakInStatements, isSpeeking: Bool, previousBuffers: [AVAudioPCMBuffer])
}

class ObserveBreakInStatements {
    weak var delegate: ObserveBreakInStatementsDelegate?
    var rmsThreshold = Float(-20.0)
    private(set) var currentRms = Float(-96.0)
    private let limitTime: TimeInterval?
    private var onDate: Date?
    private let offThreshold = TimeInterval(1)
    private(set) var isSpeeking = false
    private var speekingStartDate: Date?
    private var previousBuffers = [AVAudioPCMBuffer]()
    private let bufferlimit = 5
    
    init(limitTime: TimeInterval? = TimeInterval(50)) {
        self.limitTime = limitTime
    }
    
    func checkBreakInStatements(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        updatePreviousBuffer(buffer: buffer)
        currentRms = Rms.calculate(buffer: buffer)
        if isOverThreshold() {
            onDate = Date()
            checkSpeekingDuration()
            if !isSpeeking {
                updateSpeeakingStateTo(true)
            }
        } else {
            if checkOffTime() {
                if isSpeeking {
                    updateSpeeakingStateTo(false)
                }
            }
        }
    }
    
    func isOverThreshold() -> Bool {
        return currentRms > rmsThreshold
    }
    
    private func updatePreviousBuffer(buffer: AVAudioPCMBuffer) {
        if previousBuffers.count == bufferlimit {
            previousBuffers.remove(at: 0)
            previousBuffers.append(buffer)
        } else {
            previousBuffers.append(buffer)
        }
    }
    
    private func updateSpeeakingStateTo(_ speaking: Bool) {
        isSpeeking = speaking
        speekingStartDate = speaking ? Date() : nil
        delegate?.didChangeSpeekingState(obj: self, isSpeeking: isSpeeking, previousBuffers: previousBuffers)
    }
    
    private func checkSpeekingDuration() {
        guard let _limitTime = limitTime else { return }
        guard let startDate = speekingStartDate else { return }
        if Date().timeIntervalSince1970 - startDate.timeIntervalSince1970 > _limitTime {
            updateSpeeakingStateTo(false)
        }
    }
    
    private func checkOffTime() -> Bool {
        guard let _onDate = onDate else { return true }
        return Date().timeIntervalSince1970 - _onDate.timeIntervalSince1970 > offThreshold
    }
}
