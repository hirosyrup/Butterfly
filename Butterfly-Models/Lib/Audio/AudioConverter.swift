//
//  AudioConverter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/13.
//

import Foundation
import AVFoundation

class AudioConverter {
    static let amiVoiceFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 16000.0, channels: 1, interleaved: true)!
    
    static let voiceprintProcessingFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 44100.0, channels: 1, interleaved: true)!
    
    static let voiceprintOutputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 44100.0, channels: 1, interleaved: true)!
    
    static func convert(inputBuffer: AVAudioPCMBuffer, format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        guard let converter = AVAudioConverter(from: inputBuffer.format, to: format) else {
            throw NSError(domain: "Failed to create an audio converter.", code: -1, userInfo: nil)
        }
        
        guard let newbuffer = AVAudioPCMBuffer(pcmFormat: format,
                                               frameCapacity: AVAudioFrameCount(Float(inputBuffer.frameCapacity) * Float(format.sampleRate / inputBuffer.format.sampleRate))) else {
            throw NSError(domain: "Failed to create an pcm buffer.", code: -1, userInfo: nil)
        }
        let inputBlock : AVAudioConverterInputBlock = { (inNumPackets, outStatus) -> AVAudioBuffer? in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            let audioBuffer : AVAudioBuffer = inputBuffer
            return audioBuffer
        }
        var error : NSError?
        converter.convert(to: newbuffer, error: &error, withInputFrom: inputBlock)
        if let _error = error {
            throw _error
        }
        return newbuffer
    }
}
