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
    private let audioFile: AudioFile
    private let startTime: Float
    private let meetingId: String
    init(startTime: Float, meetingId: String, inputFormat: AVAudioFormat) {
        self.startTime = startTime
        self.meetingId = meetingId
        fileName = "\(UUID().uuidString).m4a"
        let localUrl = AudioLocalUrl.createRecordDirectoryUrl()
        let saveUrl = localUrl.appendingPathComponent("\(fileName)")
        audioFile = AudioFile.createStatementQuality(saveUrl: saveUrl, inputFormat: inputFormat)
    }
    
    func stop() {
        let data = AudioRecordData(fileName: fileName, startTime: startTime, meetingId: meetingId)
        AudioUserDefault.shared.addAudioRecordData(audioData: data)
    }
    
    func write(buffer: AVAudioPCMBuffer) {
        try? audioFile.write(buffer: buffer)
    }
}
