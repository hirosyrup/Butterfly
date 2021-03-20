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
    
    init(data: PreferencesRepository.WorkspaceData) {
        self.data = data
    }
    
    func save() -> Promise<PreferencesRepository.WorkspaceData> {
        return Promise<PreferencesRepository.WorkspaceData>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> PreferencesRepository.WorkspaceData in
                if self.data.id.isEmpty {
                    return try await(self.workspace.create(workspaceData: self.data))
                } else {
                    return try await(self.workspace.update(workspaceData: self.data))
                }
            }).then({ workspaceData in
                resolve(workspaceData)
            }).catch { (error) in
                reject(error)
            }
        }
    }
}
