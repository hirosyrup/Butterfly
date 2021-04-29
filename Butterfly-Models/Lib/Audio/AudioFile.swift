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
    
    init(saveUrl: URL, inputFormat: AVAudioFormat) {
        let format = AVAudioFormat(settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: inputFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.medium
        ])!
        audioFile = try? AVAudioFile(forWriting: saveUrl, settings: format.settings)
        self.saveUrl = saveUrl
    }
    
    func write(buffer: AVAudioPCMBuffer) throws {
        try audioFile?.write(from: buffer)
    }
}
