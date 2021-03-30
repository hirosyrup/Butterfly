//
//  AudioUploader.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/30.
//

import Foundation
import AVFoundation
import Hydra

class AudioUploader {
    let meetingId: String
    let recordDataList: [AudioRecordData]
    
    init(meetingId: String, recordDataList: [AudioRecordData]) {
        self.meetingId = meetingId
        self.recordDataList = recordDataList
    }
    
    func upload() -> Promise<String> {
        return Promise<String>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> String in
                let fileInfo = try await(self.saveFile())
                return try await(AudioStorage().upload(uploadImageUrl: fileInfo.0, fileName: fileInfo.1))
            }).then({ fileName in
                resolve(fileName)
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func saveFile() -> Promise<(URL, String)> {
        return Promise<(URL, String)>(in: .background, token: nil) { (resolve, reject, _) in
            do {
                let composition = AVMutableComposition()
                try self.recordDataList.forEach { try self.addTrack(composition: composition, recordData: $0) }
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
