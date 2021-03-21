//
//  MeetingRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation

import Foundation
import Hydra

class MeetingRepository {
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
    
    struct MeetingData {
        fileprivate let original: FirestoreMeetingData
        let id: String
        var name: String
        var userList: [MeetingUserData]
        
        init(userList: [MeetingUserData], original: FirestoreMeetingData? = nil) {
            self.userList = userList
            self.original = original ?? FirestoreMeetingData.new()
            self.id = self.original.id
            self.name = self.original.name
        }
        
        fileprivate func toFirestoreData() -> FirestoreMeetingData {
            var firestoreData = original
            firestoreData.name = name
            firestoreData.userList = userList.map({ (user) -> FirestoreMeetingUserData in
                return FirestoreMeetingUserData(id: user.id, iconName: user.iconName, name: user.name)
            })
            return firestoreData
        }
    }
    
    struct MeetingUserData {
        let id: String
        let iconName: String?
        let iconImageUrl: URL?
        let name: String
        
        init(iconImageUrl: URL?, firestoreData: FirestoreMeetingUserData) {
            self.iconImageUrl = iconImageUrl
            self.id = firestoreData.id
            self.iconName = firestoreData.iconName
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
    
    class Meeting {
        private let meeting = FirestoreMeeting()
        private let iconImage = IconImage()
        
        func create(workspaceId: String, meetingData: MeetingData) -> Promise<MeetingData> {
            return Promise<MeetingData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingData in
                    let createdFirestoreMeetingData = try await(self.meeting.add(workspaceId: workspaceId, data: meetingData.toFirestoreData()))
                    let meetingUserDataList = try createdFirestoreMeetingData.userList.map { (user) -> MeetingUserData in
                        var iconUrl: URL?
                        if let iconName = user.iconName {
                            iconUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                        }
                        return MeetingUserData(iconImageUrl: iconUrl, firestoreData: user)
                    }
                    return MeetingData(userList: meetingUserDataList, original: createdFirestoreMeetingData)
                }).then({ workspaceData in
                    resolve(workspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
    }
}
