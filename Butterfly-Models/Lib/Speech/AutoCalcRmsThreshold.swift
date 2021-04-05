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
    private let offset = Float(-2.0)
    
    init(initialThreshold: Float) {
        self.initialThreshold = initialThreshold
    }
    
    func calcThreshold(rms: Float) -> Float {
        if rmsBuffer.count == rmsBufferCount {
            rmsBuffer.remove(at: 0)
        }
        rmsBuffer.append(rms)
        
        guard rmsBuffer.count == rmsBufferCount else { return initialThreshold }
        
        let average = rmsBuffer.reduce(Float(0.0)) { $0 + $1 } / Float(rmsBufferCount)
        let sd = sqrtf(rmsBuffer.reduce(Float(0.0)) { $0 + powf((average - $1), 2.0) } / Float(rmsBufferCount))
        return average - sd + offset
    }
}
