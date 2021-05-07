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
        let voiceprintLocalUrl: URL
    }
    
    private struct OutputUrl {
        let trainingUrl: URL
        let testUrl: URL
    }
    
    private let trainingDatasetUrl: URL
    private let testDatasetUrl: URL
    private let userDataList: [PreferencesRepository.UserData]
    private let segmentDuration = 1.0
    
    init(exportUrl: URL, userDataList: [PreferencesRepository.UserData]) {
        let rootUrl = exportUrl.appendingPathComponent("dataset", isDirectory: true)
        if FileManager.default.fileExists(atPath: rootUrl.path) {
            try? FileManager.default.removeItem(at: rootUrl)
        }
        self.trainingDatasetUrl = rootUrl.appendingPathComponent("training", isDirectory: true)
        self.testDatasetUrl = rootUrl.appendingPathComponent("test", isDirectory: true)
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
            }).then({ _ in
                resolve(())
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func createOutputUrl(userId: String) -> OutputUrl {
        return OutputUrl(
            trainingUrl: makeDirectoryIfNeeded(directory: trainingDatasetUrl.appendingPathComponent(userId, isDirectory: true)),
            testUrl: makeDirectoryIfNeeded(directory: testDatasetUrl.appendingPathComponent(userId, isDirectory: true))
        )
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
                    return VoiceprintLocalData(userId: userData.id, voiceprintLocalUrl: saveUrl)
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
                let fileUrl = voiceprintLocalData.voiceprintLocalUrl
                let asset = AVAsset(url: fileUrl)
                let splitCount = asset.duration.seconds / self.segmentDuration
                let trainingFileCount = Int(splitCount * 0.75)
                let testFileCount = Int(splitCount * 0.25)
                try (0..<trainingFileCount).forEach { try await(self.splitAudio(asset: asset, segment: $0, outputUrl: outputUrl.trainingUrl)) }
                try (trainingFileCount..<trainingFileCount + testFileCount).forEach { try await(self.splitAudio(asset: asset, segment: $0, outputUrl: outputUrl.testUrl)) }
            }).then({ _ in
                resolve(())
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func splitAudio(asset: AVAsset, segment: Int, outputUrl: URL) -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
            session.outputFileType = .m4a
            let startTime = CMTime(seconds: Double(segment) * self.segmentDuration, preferredTimescale: 1000)
            if startTime > asset.duration {
                return
            }
            var endTime = CMTime(seconds: Double(segment + 1) * self.segmentDuration, preferredTimescale: 1000)
            if endTime > asset.duration {
                endTime = asset.duration
            }
            
            session.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
            session.outputURL = outputUrl.appendingPathComponent("\(segment).m4a")
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
