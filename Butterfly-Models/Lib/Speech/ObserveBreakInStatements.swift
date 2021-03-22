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
    private let rmsThrethold = Float(-15.0)
    private let limitTime = TimeInterval(50)
    private var onDate: Date?
    private let offThreshold = TimeInterval(1)
    private(set) var isSpeeking = false
    private var speekingStartDate: Date?
    let bufferSize: UInt32
    private var previousBuffers = [AVAudioPCMBuffer]()
    private let bufferlimit = 10
    
    init(bufferSize: UInt32) {
        self.bufferSize = bufferSize
    }
    
    func checkBreakInStatements(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        if let channelData = buffer.floatChannelData?[0] {
            updatePreviousBuffer(buffer: buffer)
            let channelDataArray = Array(UnsafeBufferPointer(start:channelData, count: Int(bufferSize)))
            let sum = channelDataArray.reduce(Float(0.0)) {$0 + $1 * $1} / Float(bufferSize)
            let rms = 10.0 * log10(sqrtf(sum))
            if rms > rmsThrethold {
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
        guard let startDate = speekingStartDate else { return }
        if Date().timeIntervalSince1970 - startDate.timeIntervalSince1970 > limitTime {
            updateSpeeakingStateTo(false)
        }
    }
    
    private func checkOffTime() -> Bool {
        guard let _onDate = onDate else { return true }
        return Date().timeIntervalSince1970 - _onDate.timeIntervalSince1970 > offThreshold
    }
}
