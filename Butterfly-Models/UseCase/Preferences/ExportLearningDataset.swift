//
//  ExportLearningDataset.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/04/30.
//

import Foundation
import Hydra
import AVFoundation

class ExportLearningDataset {
    private struct VoiceprintLocalData {
        let userId: String
        let voiceprintLocalUrls: [URL]
    }
    
    private let trainingDatasetUrl: URL
    private let userDataList: [PreferencesRepository.UserData]
    private let segmentDuration = 2.0
    
    init(exportUrl: URL, userDataList: [PreferencesRepository.UserData]) {
        let rootUrl = exportUrl.appendingPathComponent("dataset", isDirectory: true)
        if FileManager.default.fileExists(atPath: rootUrl.path) {
            try? FileManager.default.removeItem(at: rootUrl)
        }
        self.trainingDatasetUrl = rootUrl.appendingPathComponent("training", isDirectory: true)
        self.userDataList = userDataList.filter {$0.voicePrintName != nil}
    }
    
    func export() -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> Void in
                if self.userDataList.isEmpty {
                    throw NSError(domain: "No user has registered a voiceprint.", code: -1, userInfo: nil)
                }
                let voiceprintLocalDataList = try await(self.downloadVoiceprints())
                try voiceprintLocalDataList.forEach { (voiceprintLocalData) in
                    try await(self.exportDataset(voiceprintLocalData: voiceprintLocalData))
                }
                let backgroundData = VoiceprintLocalData(
                    userId: "background",
                    voiceprintLocalUrls: [
                        Bundle.main.url(forResource: "voiceprint_bacground1", withExtension: "wav")!,
                        Bundle.main.url(forResource: "voiceprint_bacground2", withExtension: "wav")!,
                        Bundle.main.url(forResource: "voiceprint_bacground3", withExtension: "wav")!
                    ]
                )
                try await(self.exportDataset(voiceprintLocalData: backgroundData))
            }).then({ _ in
                resolve(())
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func createOutputUrl(userId: String) -> URL {
        return makeDirectoryIfNeeded(directory: trainingDatasetUrl.appendingPathComponent(userId, isDirectory: true))
    }
    
    private func makeDirectoryIfNeeded(directory: URL) -> URL {
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        return directory
    }
    
    private func downloadVoiceprints() -> Promise<[VoiceprintLocalData]> {
        return Promise<[VoiceprintLocalData]>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> [VoiceprintLocalData] in
                return try self.userDataList.map { (userData) -> VoiceprintLocalData in
                    let fileName = userData.voicePrintName!
                    let localUrl = AudioLocalUrl.createVoiceprintDirectoryUrl()
                    let saveUrl = localUrl.appendingPathComponent(fileName)
                    if !FileManager.default.fileExists(atPath: saveUrl.path) {
                        if let downloadUrl = try await(VoiceprintStorage().fetchDownloadUrl(fileName: fileName)) {
                            let fileData = try Data(contentsOf: downloadUrl)
                            try fileData.write(to: saveUrl)
                        }
                    }
                    var voiceprintLocalUrls = [URL]()
                    voiceprintLocalUrls.append(saveUrl)
                    voiceprintLocalUrls.append(try await(VoiceprintPadding(type: .poorRecordingEnvironment1, originalFileUrl: saveUrl).execute()))
                    voiceprintLocalUrls.append(try await(VoiceprintPadding(type: .poorRecordingEnvironment2, originalFileUrl: saveUrl).execute()))
                    voiceprintLocalUrls.append(try await(VoiceprintPadding(type: .noisy, originalFileUrl: saveUrl).execute()))
                    return VoiceprintLocalData(userId: userData.id, voiceprintLocalUrls: voiceprintLocalUrls)
                }
            }).then({ saveUrls in
                resolve(saveUrls)
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func exportDataset(voiceprintLocalData: VoiceprintLocalData)-> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> Void in
                let outputUrl = self.createOutputUrl(userId: voiceprintLocalData.userId)
                var fileNumber = 0
                try voiceprintLocalData.voiceprintLocalUrls.forEach { (fileUrl) in
                    let asset = AVAsset(url: fileUrl)
                    let splitCount = Int(asset.duration.seconds / self.segmentDuration)
                    try (0..<splitCount).forEach {
                        try await(self.splitAudio(asset: asset, segment: $0, fileNumber: fileNumber, outputUrl: outputUrl))
                        fileNumber += 1
                    }
                }
            }).then({ _ in
                resolve(())
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func splitAudio(asset: AVAsset, segment: Int, fileNumber: Int, outputUrl: URL) -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)!
            session.outputFileType = .wav
            let startTime = CMTime(seconds: Double(segment) * self.segmentDuration, preferredTimescale: 1000)
            if startTime > asset.duration {
                return
            }
            var endTime = CMTime(seconds: Double(segment + 1) * self.segmentDuration, preferredTimescale: 1000)
            if endTime > asset.duration {
                endTime = asset.duration
            }
            session.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
            session.outputURL = outputUrl.appendingPathComponent("\(fileNumber).wav")
            session.exportAsynchronously(completionHandler: {
                switch session.status {
                    case AVAssetExportSession.Status.failed:
                        reject(NSError(domain: "Failed to export a training data.", code: -1, userInfo: nil))
                    default:
                        resolve(())
                }
            })
        }
    }
}
