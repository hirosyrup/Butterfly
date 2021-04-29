//
//  Rms.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/29.
//

import Foundation
import AVFoundation

class Rms {
    static func calculate(buffer: AVAudioPCMBuffer) -> Float {
        if let channelData = buffer.floatChannelData?[0] {
            let count = Int(buffer.frameCapacity)
            let channelDataArray = Array(UnsafeBufferPointer(start:channelData, count: count))
            let sum = channelDataArray.reduce(Float(0.0)) {$0 + $1 * $1} / Float(count)
            return 10.0 * log10(sqrtf(sum))
        } else {
            return -96.0
        }
    }
}
