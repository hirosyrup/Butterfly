//
//  SaveWorkspace.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/20.
//

import Foundation
import Hydra

class SaveWorkspace {
    private let data: PreferencesRepository.WorkspaceData
    private let workspace = PreferencesRepository.Workspace()
    private let MLFileUrl: URL?
    
    init(data: PreferencesRepository.WorkspaceData, MLFileUrl: URL?) {
        self.data = data
        self.MLFileUrl = MLFileUrl
    }
    
    func save() -> Promise<PreferencesRepository.WorkspaceData> {
        return Promise<PreferencesRepository.WorkspaceData>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> PreferencesRepository.WorkspaceData in
                var uploadData = self.data
                if let _MLFileUrl = self.MLFileUrl {
                    if uploadData.mlFileName != _MLFileUrl.lastPathComponent{
                        if (uploadData.mlFileName != nil) {try await(self.deleteMLFile(fileName: uploadData.mlFileName!))}
                        let fileName = "\(UUID().uuidString).mlmodel"
                        uploadData.mlFileName = try await(self.uploadMLFile(uploadFileUrl: _MLFileUrl, fileName: fileName))
                    }
                }
                if uploadData.id.isEmpty {
                    return try await(self.workspace.create(workspaceData: uploadData))
                } else {
                    return try await(self.workspace.update(workspaceData: uploadData))
                }
            }).then({ workspaceData in
                resolve(workspaceData)
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func deleteMLFile(fileName: String) -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ in
                try await(MLStorage().delete(fileName: fileName))
            }).then({ _ in
                resolve(())
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func uploadMLFile(uploadFileUrl: URL, fileName: String) -> Promise<String> {
        return Promise<String>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> String in
                return try await(MLStorage().upload(uploadFileUrl: uploadFileUrl, fileName: fileName))
            }).then({ filrPath in
                resolve(filrPath)
            }).catch { (error) in
                reject(error)
            }
        }
    }
}
