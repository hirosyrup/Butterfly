//
//  AudioRecorder.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/29.
//

import Foundation
import AVFoundation
import Hydra

class AudioRecorder {
    private let fileName: String
    private var audioFile: AVAudioFile?
    private let startTime: Float
    private let meetingId: String
    init(startTime: Float, meetingId: String, inputFormat: AVAudioFormat) {
        self.startTime = startTime
        self.meetingId = meetingId
        fileName = "\(UUID().uuidString).m4a"
        let localUrl = AudioLocalUrl.createRecordDirectoryUrl()
        let saveUrl = localUrl.appendingPathComponent("\(fileName)")
        let format = AVAudioFormat(settings: [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: inputFormat.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.max
        ])!
        audioFile = try? AVAudioFile(forWriting: saveUrl, settings: format.settings)
    }
    
    func stop() -> Promise<Void> {
        audioFile = nil
        let audioUserDefault = AudioUserDefault.shared
        let data = AudioRecordData(fileName: fileName, startTime: startTime, meetingId: meetingId)
        audioUserDefault.addAudioRecordData(audioData: data)
        let recordDataList = AudioUserDefault.shared.audioRecordDataList().filter({ $0.meetingId == self.meetingId })
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> (URL, String) in
                return try await(self.mergeFile(recordDataList: recordDataList))
            }).then({ fileInfo in
                let data = AudioRecordData(fileName: fileInfo.1, startTime: 0.0, meetingId: self.meetingId)
                audioUserDefault.addAudioRecordData(audioData: data)
                audioUserDefault.removeAudioRecordData(dataList: recordDataList)
                resolve(())
            }).catch { (error) in
                print("\(error.localizedDescription)")
                reject(error)
            }
        }
    }
    
    func write(buffer: AVAudioPCMBuffer) {
        try? audioFile?.write(from: buffer)
    }
    
    private func mergeFile(recordDataList: [AudioRecordData]) -> Promise<(URL, String)> {
        return Promise<(URL, String)>(in: .background, token: nil) { (resolve, reject, _) in
            do {
                let composition = AVMutableComposition()
                try recordDataList.forEach { try self.addTrack(composition: composition, recordData: $0) }
                guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
                    throw NSError(domain: "Failed to prepare session", code: -1, userInfo: nil)
                }
                let fileName = "\(UUID().uuidString).m4a"
                let outputUrl = AudioLocalUrl.createRecordDirectoryUrl().appendingPathComponent(fileName)
                session.outputURL = outputUrl
                session.outputFileType = .m4a
                session.exportAsynchronously {
                    switch session.status {
                    case .completed:
                        resolve((outputUrl, fileName))
                    default:
                        reject(session.error ?? NSError(domain: "Failed to save File", code: -1, userInfo: nil))
                    }
                }
            } catch {
                reject(error)
            }
        }
    }
    
    private func addTrack(composition: AVMutableComposition, recordData: AudioRecordData) throws {
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())
        let localUrl = AudioLocalUrl.createRecordDirectoryUrl()
        let fileUrl = localUrl.appendingPathComponent("\(recordData.fileName)")
        let asset = AVURLAsset(url: fileUrl)
        let tracks = asset.tracks(withMediaType: .audio)
        let assetTrack = tracks[0]
        let startTime = CMTime(seconds: Double(recordData.startTime), preferredTimescale: 1000)
        try compositionAudioTrack?.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: startTime)
    }
}
