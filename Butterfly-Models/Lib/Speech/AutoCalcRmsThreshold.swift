//
//  AutoCalcRmsThreshold.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/06.
//

import Foundation

class AutoCalcRmsThreshold {
    private let initialThreshold: Float
    private let rmsBufferCount = 5
    private var rmsBuffer = [Float]()
    private let thresholdBufferCount = 10
    private var thresholdBuffer = [Float]()
    private let offset = Float(-3.0)
    
    init(initialThreshold: Float) {
        self.initialThreshold = initialThreshold
    }
    
    func calcThreshold(rms: Float) -> Float {
        if rmsBuffer.count == rmsBufferCount {
            rmsBuffer.remove(at: 0)
        }
        rmsBuffer.append(rms)
        
        guard rmsBuffer.count == rmsBufferCount else { return initialThreshold }
        
        let threshold = rmsBuffer.reduce(Float(0.0)) { $0 + $1 } / Float(rmsBufferCount)
    
        if thresholdBuffer.count != thresholdBufferCount {
            thresholdBuffer.append(threshold)
            return initialThreshold
        }
        
        let averageThreshold = thresholdBuffer.reduce(Float(0.0)) { $0 + $1 } / Float(thresholdBufferCount)
        let returnThreshold = averageThreshold + offset
        
        if threshold > returnThreshold {
            thresholdBuffer.remove(at: 0)
            thresholdBuffer.append(threshold)
        }
        
        return returnThreshold
    }
}
