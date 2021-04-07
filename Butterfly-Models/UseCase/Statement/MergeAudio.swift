//
//  MergeAudio.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/31.
//

import Foundation
import Hydra
import AVFoundation

class MergeAudio {
    private let meetingData: MeetingRepository.MeetingData
    private let meetingUserDataList: [MeetingUserRepository.MeetingUserData]
    
    init(meetingData: MeetingRepository.MeetingData, meetingUserDataList: [MeetingUserRepository.MeetingUserData]) {
        self.meetingData = meetingData
        self.meetingUserDataList = meetingUserDataList
    }
    
    func merge() -> Promise<AVMutableComposition> {
        return Promise<AVMutableComposition>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> AVMutableComposition in
                let audioFileNames = self.meetingUserDataList.filter { $0.audioFileName != nil }.map { $0.audioFileName! }
                try audioFileNames.forEach { (fileName) in
                    let fileUrl = AudioLocalUrl.createAudioDirectoryUrl().appendingPathComponent(fileName)
                    if !FileManager.default.fileExists(atPath: fileUrl.path) {
                        if let downloadUrl = try await(AudioStorage().fetchDownloadUrl(fileName: fileName)) {
                            if let audioData = try? Data(contentsOf: downloadUrl) {
                                try audioData.write(to: fileUrl)
                            }
                        }
                    }
                }
                
                let composition = AVMutableComposition()
                let fileUrls = audioFileNames.map { AudioLocalUrl.createAudioDirectoryUrl().appendingPathComponent($0) }
                try fileUrls.forEach { try self.addTrack(composition: composition, fileUrl: $0) }
                return composition
            }).then({ composition in
                resolve(composition)
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func addTrack(composition: AVMutableComposition, fileUrl: URL) throws {
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())
        let asset = AVURLAsset(url: fileUrl)
        let tracks = asset.tracks(withMediaType: .audio)
        let assetTrack = tracks[0]
        let startTime = CMTime(seconds: 0.0, preferredTimescale: 1000)
        try compositionAudioTrack?.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: startTime)
    }
}
