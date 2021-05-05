//
//  DownloadMLFile.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/25.
//

import Foundation
import Hydra
import CoreML

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
                        if let mlFileData = try? Data(contentsOf: downloadUrl) {
                            try mlFileData.write(to: fileUrl)
                        }
                    }
                }
                let compiledFileName = MLFileLocalUrl.createCompiledModelFileName(modelFileName: self.fileName)
                let compiledFileUrl = MLFileLocalUrl.createLocalUrl().appendingPathComponent(compiledFileName)
                if !FileManager.default.fileExists(atPath: compiledFileUrl.path) {
                    let url = try MLModel.compileModel(at: fileUrl)
                    try FileManager.default.copyItem(at: url, to: compiledFileUrl)
                }
            }).then({ _ in
                resolve(())
            }).catch { (error) in
                reject(error)
            }
        }
    }
}
