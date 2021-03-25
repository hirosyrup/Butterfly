//
//  MeetingRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra

protocol MeetingRepositoryDelegate: class {
    func didChangeMeetingData(obj: MeetingRepository.Meeting, documentChanges: [RepositoryDocumentChange<MeetingRepository.MeetingData>])
}

class MeetingRepository {
    struct MeetingData {
        fileprivate let original: FirestoreMeetingData
        let id: String
        var name: String
        var createdAt: Date
        var userList: [MeetingUserData]
        
        init(userList: [MeetingUserData], original: FirestoreMeetingData? = nil) {
            self.userList = userList
            self.original = original ?? FirestoreMeetingData.new()
            self.id = self.original.id
            self.createdAt = self.original.createdAt
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
        private let iconImage = IconImage.shared
        
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
    
    class Meeting: FirestoreMeetingDelegate {
        private let meeting = FirestoreMeeting()
        private let iconImage = IconImage.shared
        weak var delegate: MeetingRepositoryDelegate?
        
        init() {
            meeting.delegate = self
        }
        
        func listen(workspaceId: String) {
            meeting.listen(workspaceId: workspaceId)
        }
        
        func unlisten() {
            meeting.unlisten()
        }
        
        func index(workspaceId: String) -> Promise<[MeetingData]> {
            return Promise<[MeetingData]>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> [MeetingData] in
                    let firestoreMeetingDataList = try await(self.meeting.index(workspaceId: workspaceId))
                    return try firestoreMeetingDataList.map { (firestoreMeetingData) -> MeetingData in
                        return try await(self.createMeetingData(firestoreMeetingData: firestoreMeetingData))
                    }
                }).then({ workspaceData in
                    resolve(workspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func fetch(workspaceId: String, meetingId: String) -> Promise<MeetingData?> {
            return Promise<MeetingData?>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingData? in
                    if let firestoreMeetingData = try await(self.meeting.fetch(workspaceId: workspaceId, meetingId: meetingId)) {
                        return try await(self.createMeetingData(firestoreMeetingData: firestoreMeetingData))
                    } else {
                        return nil
                    }
                }).then({ workspaceData in
                    resolve(workspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
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
        
        func didChangeMeetingData(obj: FirestoreMeeting, documentChanges: [FirestoreDocumentChangeWithData<FirestoreMeetingData>]) {
            if let _delegate = delegate {
                async({ _ -> [RepositoryDocumentChange<MeetingData>] in
                    return try documentChanges.map { (documentChange) -> RepositoryDocumentChange<MeetingData> in
                        let meetingData = try await(self.createMeetingData(firestoreMeetingData: documentChange.firestoreData))
                        return RepositoryDocumentChange<MeetingData>(documentChange: documentChange.documentChange, data: meetingData)
                    }
                }).then({ changes in
                    _delegate.didChangeMeetingData(obj: self, documentChanges: changes)
                }).catch { (error) in
                    print("\(error.localizedDescription)")
                }
            }
        }
    }
}
