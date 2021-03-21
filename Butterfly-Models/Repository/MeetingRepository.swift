//
//  MeetingRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import Hydra

class MeetingRepository {
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
        
        init(iconImageUrl: URL?, firestoreData: FirestoreUserData) {
            self.iconImageUrl = iconImageUrl
            self.id = firestoreData.id
            self.iconName = firestoreData.iconName
            self.name = firestoreData.name
        }
    }
    
    class User {
        private let workspace = FirestoreWorkspace()
        private let user = FirestoreUser()
        private let iconImage = IconImage()
        
        func fetchUsers(workspaceId: String) -> Promise<[MeetingUserData]> {
            return Promise<[MeetingUserData]>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> [MeetingUserData] in
                    let firestoreWorkspaceData = try await(self.workspace.fetch(workspaceId: workspaceId))!
                    let firestoreUserDataList = try await(self.user.index(userIdList: firestoreWorkspaceData.userIdList))
                    return try firestoreUserDataList.map { (userData) -> MeetingUserData in
                        var iconUrl: URL?
                        if let iconName = userData.iconName {
                            iconUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                        }
                        return MeetingUserData(iconImageUrl: iconUrl, firestoreData: userData)
                    }
                }).then({ meetingUserDataList in
                    resolve(meetingUserDataList)
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
                    return try await(self.createMeetingData(firestoreMeetingData: createdFirestoreMeetingData))
                }).then({ workspaceData in
                    resolve(workspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func update(workspaceId: String, meetingData: MeetingData) -> Promise<MeetingData> {
            return Promise<MeetingData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingData in
                    let meetingId = meetingData.original.id
                    let firestoreMeetingData = meetingData.toFirestoreData().copyCurrentAt()
                    let savedFirestoreMeetingData = try await(self.meeting.update(workspaceId: workspaceId, meetingId: meetingId, data: firestoreMeetingData))
                    return try await(self.createMeetingData(firestoreMeetingData: savedFirestoreMeetingData))
                }).then({newMeetingData in
                    resolve(newMeetingData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        private func createMeetingData(firestoreMeetingData: FirestoreMeetingData) -> Promise<MeetingData> {
            return Promise<MeetingData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingData in
                    let meetingUserDataList = try firestoreMeetingData.userList.map { (user) -> MeetingUserData in
                        var iconUrl: URL?
                        if let iconName = user.iconName {
                            iconUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                        }
                        return MeetingUserData(iconImageUrl: iconUrl, firestoreData: user)
                    }
                    return MeetingData(userList: meetingUserDataList, original: firestoreMeetingData)
                }).then({newWorkspaceData in
                    resolve(newWorkspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
    }
}
