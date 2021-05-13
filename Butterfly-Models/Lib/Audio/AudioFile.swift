//
//  AudioFile.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/29.
//

import Foundation
import AVFoundation

class AudioFile {
    let saveUrl: URL
    private let audioFile: AVAudioFile?
    
    static func createStatementQuality(saveUrl: URL, inputFormat: AVAudioFormat) -> AudioFile {
        let format = AVAudioFormat(settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: inputFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.medium
        ])!
        return AudioFile(saveUrl: saveUrl, format: format)
    }
    
    init(saveUrl: URL, format: AVAudioFormat) {
        audioFile = try? AVAudioFile(forWriting: saveUrl, settings: format.settings)
        self.saveUrl = saveUrl
    }
    
    func write(buffer: AVAudioPCMBuffer) throws {
        try audioFile?.write(from: buffer)
    }
}
