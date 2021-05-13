//
//  VoiceprintPadding.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/12.
//

import Foundation
import Hydra
import AVFoundation

class VoiceprintPadding {
    private let type: VoiceprintPaddingType
    private let originalFileUrl: URL
    
    init(type: VoiceprintPaddingType, originalFileUrl: URL) {
        self.type = type
        self.originalFileUrl = originalFileUrl
    }
    
    func execute() -> Promise<URL> {
        return Promise<URL>(in: .background, token: nil) { (resolve, reject, _) in
            do {
                let fileUrl = try self.exportUrl()
                try await(self.create(fileUrl: fileUrl))
                resolve(fileUrl)
            } catch {
                reject(error)
            }
        }
    }
    
    private func exportUrl() throws -> URL {
        let folderName: String
        switch type {
        case .spatial:
            folderName = "spatial"
        case .poorRecordingEnvironment1:
            folderName = "poorRecordingEnvironment1"
        case .poorRecordingEnvironment2:
            folderName = "poorRecordingEnvironment2"
        case .noisy:
            folderName = "noisy"
        }
        
        let exportDirectory = originalFileUrl.deletingLastPathComponent().appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: exportDirectory.path) {
            try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return exportDirectory.appendingPathComponent(originalFileUrl.lastPathComponent)
    }
    
    private func create(fileUrl: URL) throws -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            let sourceFile = try AVAudioFile(forReading: self.originalFileUrl)
            let format = sourceFile.processingFormat
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            let effectNode = self.createEffectNode()
            engine.attach(player)
            engine.attach(effectNode)
            engine.connect(player, to: effectNode, format: format)
            engine.connect(effectNode, to: engine.mainMixerNode, format: format)
            
            player.scheduleFile(sourceFile, at: nil)
            
            try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
            
            try engine.start()
            player.play()
            
            let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat,
                                          frameCapacity: engine.manualRenderingMaximumFrameCount)!
            let outputFile = try AVAudioFile(forWriting: fileUrl, settings: sourceFile.fileFormat.settings)
            
            while engine.manualRenderingSampleTime < sourceFile.length {
                let frameCount = sourceFile.length - engine.manualRenderingSampleTime
                let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)
                let status = try engine.renderOffline(framesToRender, to: buffer)
                switch status {
                case .success:
                    try outputFile.write(from: buffer)
                case .insufficientDataFromInputNode:
                    break
                case .cannotDoInCurrentContext:
                    break
                case .error:
                    throw NSError(domain: "Failed to create a voiceprint padding data.", code: -1, userInfo: nil)
                @unknown default:
                    fatalError("The manual rendering failed. unknown status.")
                }
            }
            
            player.stop()
            engine.stop()
            
            resolve(())
        }
    }
    
    private func createEffectNode() -> AVAudioNode {
        switch type {
        case .spatial:
            let node = AVAudioUnitReverb()
            node.loadFactoryPreset(.smallRoom)
            node.wetDryMix = 5
            return node
        case .poorRecordingEnvironment1:
            let node = AVAudioUnitEQ(numberOfBands: 1)
            let param = node.bands.first!
            param.bypass = false
            param.filterType = .lowPass
            param.frequency = 2000.0
            param.gain = 6.0
            return node
        case .poorRecordingEnvironment2:
            let node = AVAudioUnitEQ(numberOfBands: 1)
            let param = node.bands.first!
            param.bypass = false
            param.filterType = .highPass
            param.frequency = 300.0
            param.gain = 6.0
            return node
        case .noisy:
            let node = AVAudioUnitDistortion()
            node.preGain = -10.0
            return node
        }
    }
}
