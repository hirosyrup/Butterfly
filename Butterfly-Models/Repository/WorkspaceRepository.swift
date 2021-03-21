//
//  WorkspaceRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import Hydra

class WorkspaceRepository {
    struct UserData {
        let id: String
        let iconImageUrl: URL?
        let name: String
        let workspaceList: [WorkspaceData]
        
        init(iconImageUrl: URL?, workspaceList: [WorkspaceData], firestoreData: FirestoreUserData) {
            self.iconImageUrl = iconImageUrl
            self.workspaceList = workspaceList
            self.id = firestoreData.id
            self.name = firestoreData.name
        }
    }
    
    struct WorkspaceData {
        let id: String
        let name: String
        
        init(firestoreData: FirestoreWorkspaceData) {
            self.id = firestoreData.id
            self.name = firestoreData.name
        }
    }
    
    class User {
        private let user = FirestoreUser()
        private let workspace = FirestoreWorkspace()
        private let iconImage = IconImage()
        private let userId: String
        
        init(userId: String) {
            self.userId = userId
        }
        
        func fetch() -> Promise<UserData> {
            return Promise<UserData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> UserData in
                    let firestoreUserData = try await(self.user.fetch(userId: self.userId))!
                    var iconUrl: URL?
                    if let iconName = firestoreUserData.iconName {
                        iconUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                    }
                    
                    let firestoreWorkspaceDatas = try await(self.workspace.index(userId: self.userId))
                    let workspaceDatas = firestoreWorkspaceDatas.map { (firestoreWorkspaceData) -> WorkspaceData in
                        return WorkspaceData(firestoreData: firestoreWorkspaceData)
                    }
                    
                    return UserData(iconImageUrl: iconUrl, workspaceList: workspaceDatas, firestoreData: firestoreUserData)
                }).then({ userData in
                    resolve(userData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
    }
}
