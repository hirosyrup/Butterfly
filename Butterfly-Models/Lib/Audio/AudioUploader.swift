//
//  AudioUploader.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/30.
//

import Foundation
import AVFoundation

class AudioUploader {
    let meetingId: String
    let recordDataList: [AudioRecordData]
    
    init(meetingId: String, recordDataList: [AudioRecordData]) {
        self.meetingId = meetingId
        self.recordDataList = recordDataList
    }
    
    func prepare() {
        var composition = AVMutableComposition()
        recordDataList.forEach { addTrack(composition: composition, recordData: $0) }
    }
    
    private func addTrack(composition: AVMutableComposition, recordData: AudioRecordData) {
        var compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())
        let localUrl = AudioLocalUrl.createLocalUrl()
        let fileUrl = localUrl.appendingPathComponent("\(recordData.fileName)")
        let asset = AVURLAsset(url: fileUrl)
        let tracks = asset.tracks(withMediaType: .audio)
        let assetTrak = tracks[0] as! AVAssetTrack
        let duration = assetTrak.timeRange.duration
        let startTime = CMTime(seconds: Double(recordData.startTime), preferredTimescale: CMTimeScale())
        let range = CMTimeRange(start: , duration: <#T##CMTime#>)
    }
}
