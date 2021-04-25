//
//  DownloadMLFile.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/25.
//

import Foundation
import Hydra

class DownloadMLFile {
    private let fileName: String
    
    init(fileName: String) {
        self.fileName = fileName
    }
    
    func download() -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> Void in
                let fileUrl = MLFileLocalUrl.createLocalUrl().appendingPathComponent(self.fileName)
                if !FileManager.default.fileExists(atPath: fileUrl.path) {
                    if let downloadUrl = try await(MLStorage().fetchDownloadUrl(fileName: self.fileName)) {
                        if let audioData = try? Data(contentsOf: downloadUrl) {
                            try audioData.write(to: fileUrl)
                        }
                    }
                }
            }).then({ _ in
                resolve(())
            }).catch { (error) in
                reject(error)
            }
        }
    }
}
