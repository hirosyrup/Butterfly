//
//  PreferencesRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation
import Hydra
class PreferencesRepository {
    struct UserData {
        fileprivate let original: FirestoreUserData
        let id: String
        var iconName: String?
        var iconImageUrl: URL?
        var name: String
        
        init(iconImageUrl: URL?, original: FirestoreUserData? = nil) {
            
            self.iconImageUrl = iconImageUrl
            self.original = original ?? FirestoreUserData.new()
            self.id = self.original.id
            self.iconName = self.original.iconName
            self.name = self.original.name
        }
        
        fileprivate func toFirestoreData() -> FirestoreUserData {
            var firestoreData = original
            firestoreData.iconName = iconName
            firestoreData.name = name
            return firestoreData
        }
    }

    struct WorkspaceData {
        fileprivate let original: FirestoreWorkspaceData
        let id: String
        var name: String
        var users: [UserData]
        
        init(users: [UserData], original: FirestoreWorkspaceData? = nil) {
            self.users = users
            self.original = original ?? FirestoreWorkspaceData.new()
            self.id = self.original.id
            self.name = self.original.name
        }
        
        fileprivate func toFirestoreData() -> FirestoreWorkspaceData {
            var firestoreData = original
            firestoreData.name = name
            firestoreData.userIdList = users.map({ (user) -> String in
                return user.id
            })
            return firestoreData
        }
    }
    
    class User {
        private let user = FirestoreUser()
        private let iconImage = IconImage.shared
        
        func index() -> Promise<[UserData]> {
            return Promise<[UserData]>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> [UserData] in // you must specify the return of the Promise, here an Int
                    let firestoreUserDatas = try await(self.user.index())
                    return try firestoreUserDatas.map { (firestoreUserData) -> UserData in
                        return try await(self.createUserData(firestoreUserData: firestoreUserData))
                    }
                }).then({ userDataList in
                    resolve(userDataList)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func findOrCreate(userId: String) -> Promise<UserData> {
            return Promise<UserData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> UserData in
                    var firestoreUserData = try await(self.user.fetch(userId: userId))
                    if firestoreUserData == nil {
                        var newUserData = FirestoreUserData.new()
                        newUserData = try await(self.user.save(data: newUserData, userId: userId))
                        firestoreUserData = newUserData
                    }
                    return try await(self.createUserData(firestoreUserData: firestoreUserData!))
                }).then({ userData in
                    resolve(userData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func update(userData: UserData) -> Promise<UserData> {
            return Promise<UserData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> UserData in
                    let userId = userData.original.id
                    let firestoreUserData = userData.toFirestoreData().copyCurrentAt()
                    let savedFirestoreUserData = try await(self.user.save(data: firestoreUserData, userId: userId))
                    return try await(self.createUserData(firestoreUserData: savedFirestoreUserData))
                }).then({newUserData in
                    resolve(newUserData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        private func createUserData(firestoreUserData: FirestoreUserData) -> Promise<UserData> {
            return Promise<UserData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> UserData in
                    var userData = UserData(iconImageUrl: nil, original: firestoreUserData)
                    
                    if let iconName = firestoreUserData.iconName {
                        let downloadUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                        userData.iconName = iconName
                        userData.iconImageUrl = downloadUrl
                    }
                    
                    return userData
                }).then({newUserData in
                    resolve(newUserData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
    }
    
    class Workspace {
        private let workspace = FirestoreWorkspace()
        private let userRepository = PreferencesRepository.User()
        private let iconImage = IconImage.shared
        
        func index(userId: String) -> Promise<[WorkspaceData]> {
            return Promise<[WorkspaceData]>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> [WorkspaceData] in
                    let firestoreWorkspaceDatas = try await(self.workspace.index(userId: userId))
                    return try firestoreWorkspaceDatas.map { (firestoreWorkspaceData) -> WorkspaceData in
                        return try await(self.createWorkspaceData(firestoreWorkspaceData: firestoreWorkspaceData))
                    }
                }).then({ workspaceDataList in
                    resolve(workspaceDataList)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func create(workspaceData: WorkspaceData) -> Promise<WorkspaceData> {
            return Promise<WorkspaceData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> WorkspaceData in
                    let createdFirestoreWorkspaceData = try await(self.workspace.add(data: workspaceData.toFirestoreData()))
                    return try await(self.createWorkspaceData(firestoreWorkspaceData: createdFirestoreWorkspaceData))
                }).then({ workspaceData in
                    resolve(workspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
    
        func update(workspaceData: WorkspaceData) -> Promise<WorkspaceData> {
            return Promise<WorkspaceData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> WorkspaceData in
                    let workspaceId = workspaceData.original.id
                    let firestoreWorkspaceData = workspaceData.toFirestoreData().copyCurrentAt()
                    let savedFirestoreWorkspaceData = try await(self.workspace.update(data: firestoreWorkspaceData, workspaceId: workspaceId))
                    return try await(self.createWorkspaceData(firestoreWorkspaceData: savedFirestoreWorkspaceData))
                }).then({newWorkspaceData in
                    resolve(newWorkspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        private func createWorkspaceData(firestoreWorkspaceData: FirestoreWorkspaceData) -> Promise<WorkspaceData> {
            return Promise<WorkspaceData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> WorkspaceData in
                    let userDataList = try firestoreWorkspaceData.userIdList.map { (userId) -> UserData in
                        return try await(self.userRepository.findOrCreate(userId: userId))
                    }
                    return WorkspaceData(users: userDataList, original: firestoreWorkspaceData)
                }).then({newWorkspaceData in
                    resolve(newWorkspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
    }
}
