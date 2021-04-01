//
//  AudioExport.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/02.
//

import Foundation
import AVFoundation
import Hydra

class AudioExport {
    private let composition: AVMutableComposition
    private let outputUrl: URL
    
    init(composition: AVMutableComposition, outputUrl: URL) {
        self.composition = composition
        self.outputUrl = outputUrl
    }
    
    func export() -> Promise<URL> {
        return Promise<URL>(in: .background, token: nil) { (resolve, reject, _) in
            do {
                guard let session = AVAssetExportSession(asset: self.composition, presetName: AVAssetExportPresetAppleM4A) else {
                    throw NSError(domain: "Failed to prepare session", code: -1, userInfo: nil)
                }
                session.outputURL = self.outputUrl
                session.outputFileType = .m4a
                session.exportAsynchronously {
                    switch session.status {
                    case .completed:
                        resolve(self.outputUrl)
                    default:
                        reject(session.error ?? NSError(domain: "Failed to export an audio file.", code: -1, userInfo: nil))
                    }
                }
            } catch {
                reject(error)
            }
        }
    }
}
