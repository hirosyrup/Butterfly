//
//  AudioRecorder.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/29.
//

import Foundation
import AVFoundation

class AudioRecorder {
    private let fileName: String
    private let audioFile: AVAudioFile?
    private let startTime: Float
    private var endTime: Float?
    private let meetingId: String
    init(startTime: Float, meetingId: String, inputFormat: AVAudioFormat) {
        self.startTime = startTime
        self.meetingId = meetingId
        fileName = "\(UUID().uuidString).m4a"
        let localUrl = AudioLocalUrl.createLocalUrl()
        let saveUrl = localUrl.appendingPathComponent("\(fileName)")
        let format = AVAudioFormat(settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: inputFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.medium
        ])!
        audioFile = try? AVAudioFile(forWriting: saveUrl, settings: format.settings)
    }
    
    func stop(endTime: Float) {
        self.endTime = endTime
        let data = AudioRecordData(fileName: fileName, startTime: startTime, endTime: endTime, meetingId: meetingId)
        AudioUserDefault.shared.addAudioRecordData(audioData: data)
    }
    
    func write(buffer: AVAudioPCMBuffer) {
        guard endTime == nil else { return }
        try? audioFile?.write(from: buffer)
    }
}
