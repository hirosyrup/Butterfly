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
import SwiftyBeaver

protocol MeetingRepositoryDataListDelegate: class {
    func didChangeMeetingDataList(obj: MeetingRepository.Meeting, documentChanges: [RepositoryDocumentChange<MeetingRepository.MeetingData>])
}

protocol MeetingRepositoryDataDelegate: class {
    func didChangeMeetingData(obj: MeetingRepository.Meeting, data: MeetingRepository.MeetingData)
}

class MeetingRepository {
    enum MeetingStatus: Int {
        case open = 0
        case archived = 1
    }
    
    struct MeetingData {
        fileprivate let original: FirestoreMeetingData
        let id: String
        var name: String
        var status: MeetingStatus
        var startedAt: Date?
        var endedAt: Date?
        var createdAt: Date
        var iconList: [MeetingIconData]
        
        init(iconList: [MeetingIconData], original: FirestoreMeetingData? = nil) {
            self.iconList = iconList
            self.original = original ?? FirestoreMeetingData.new()
            self.id = self.original.id
            self.createdAt = self.original.createdAt
            self.name = self.original.name
            self.status = MeetingStatus(rawValue: self.original.status)!
            self.startedAt = self.original.startedAt
            self.endedAt = self.original.endedAt
        }
        
        fileprivate func toFirestoreData() -> FirestoreMeetingData {
            var firestoreData = original
            firestoreData.name = name
            firestoreData.status = status.rawValue
            firestoreData.startedAt = startedAt
            firestoreData.endedAt = endedAt
            firestoreData.iconList = iconList.map({ (user) -> FirestoreMeetingIconData in
                return FirestoreMeetingIconData(userId: user.userId, iconName: user.iconName, name: user.name)
            })
            return firestoreData
        }
    }
    
    struct MeetingIconData {
        let userId: String
        let iconName: String?
        let iconImageUrl: URL?
        let name: String
        
        init(iconImageUrl: URL?, firestoreData: FirestoreMeetingIconData) {
            self.iconImageUrl = iconImageUrl
            self.userId = firestoreData.userId
            self.iconName = firestoreData.iconName
            self.name = firestoreData.name
        }
        
        init(iconImageUrl: URL?, firestoreData: FirestoreUserData) {
            self.iconImageUrl = iconImageUrl
            self.userId = firestoreData.id
            self.iconName = firestoreData.iconName
            self.name = firestoreData.name
        }
        
        fileprivate func toFirestoreData() -> FirestoreMeetingIconData {
            return FirestoreMeetingIconData(userId: userId, iconName: iconName, name: name)
        }
        
        fileprivate func createMeetingUserData() -> FirestoreMeetingUserData {
            return FirestoreMeetingUserData(id: "", userId: userId, iconName: iconName, name: name, isHost: false, isEntering: false, audioFileName: nil, createdAt: Date(), updatedAt: Date())
        }
    }
    
    class User {
        private let workspace = FirestoreWorkspace()
        private let user = FirestoreUser()
        private let iconImage = IconImage.shared
        
        func fetchUsers(workspaceId: String) -> Promise<[MeetingIconData]> {
            return Promise<[MeetingIconData]>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> [MeetingIconData] in
                    let firestoreWorkspaceData = try await(self.workspace.fetch(workspaceId: workspaceId))!
                    let firestoreUserDataList = try await(self.user.index(userIdList: firestoreWorkspaceData.userIdList))
                    return try firestoreUserDataList.map { (userData) -> MeetingIconData in
                        var iconUrl: URL?
                        if let iconName = userData.iconName {
                            iconUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                        }
                        return MeetingIconData(iconImageUrl: iconUrl, firestoreData: userData)
                    }
                }).then({ meetingIconDataList in
                    resolve(meetingIconDataList)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
    }
    
    class Meeting: FirestoreMeetingDataListDelegate, FirestoreMeetingDataDelegate {
        private let meeting = FirestoreMeeting()
        private let meetingUser = FirestoreMeetingUser()
        private let iconImage = IconImage.shared
        private weak var dataListDelegate: MeetingRepositoryDataListDelegate?
        private weak var dataDelegate: MeetingRepositoryDataDelegate?
        private(set) var listenWorkspaceId: String?
        
        init() {
            meeting.dataListDelegate = self
            meeting.dataDelegate = self
        }
        
        func listen(workspaceId: String, dataListDelegate: MeetingRepositoryDataListDelegate) {
            self.dataListDelegate = dataListDelegate
            listenWorkspaceId = workspaceId
            meeting.listen(workspaceId: workspaceId)
        }
        
        func listen(workspaceId: String, meetingId: String, dataDelegate: MeetingRepositoryDataDelegate) {
            self.dataDelegate = dataDelegate
            listenWorkspaceId = workspaceId
            meeting.listen(workspaceId: workspaceId, meetingId: meetingId)
        }
        
        func unlisten() {
            dataListDelegate = nil
            dataDelegate = nil
            listenWorkspaceId = nil
            meeting.unlisten()
        }
        
        func index(workspaceId: String) -> Promise<[MeetingData]> {
            return Promise<[MeetingData]>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> [MeetingData] in
                    let firestoreMeetingDataList = try await(self.meeting.index(workspaceId: workspaceId))
                    return try firestoreMeetingDataList.map { (firestoreMeetingData) -> MeetingData in
                        return try await(self.createMeetingData(workspaceId: workspaceId, firestoreMeetingData: firestoreMeetingData))
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
                        return try await(self.createMeetingData(workspaceId: workspaceId, firestoreMeetingData: firestoreMeetingData))
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
                    let _ = try meetingData.iconList.map({ (user) -> FirestoreMeetingUserData in
                        return try await(self.meetingUser.add(workspaceId: workspaceId, meetingId: createdFirestoreMeetingData.id, data: user.createMeetingUserData()))
                    })
                    return try await(self.createMeetingData(workspaceId: workspaceId, firestoreMeetingData: createdFirestoreMeetingData))
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
                    return try await(self.createMeetingData(workspaceId: workspaceId, firestoreMeetingData: savedFirestoreMeetingData))
                }).then({newMeetingData in
                    resolve(newMeetingData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func updateWithUser(workspaceId: String, meetingData: MeetingData) -> Promise<MeetingData> {
            return Promise<MeetingData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingData in
                    let meetingId = meetingData.original.id
                    let firestoreMeetingData = meetingData.toFirestoreData().copyCurrentAt()
                    let savedFirestoreMeetingData = try await(self.meeting.update(workspaceId: workspaceId, meetingId: meetingId, data: firestoreMeetingData))
                    try await(self.meetingUser.deleteAll(workspaceId: workspaceId, meetingId: meetingData.id))
                    let _ = try meetingData.iconList.map({ (user) -> FirestoreMeetingUserData in
                        return try await(self.meetingUser.add(workspaceId: workspaceId, meetingId: savedFirestoreMeetingData.id, data: user.createMeetingUserData()))
                    })
                    return try await(self.createMeetingData(workspaceId: workspaceId, firestoreMeetingData: savedFirestoreMeetingData))
                }).then({newMeetingData in
                    resolve(newMeetingData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func archive(workspaceId: String, meetingData: MeetingData) -> Promise<MeetingData> {
            var updateData = meetingData
            updateData.status = .archived
            return update(workspaceId: workspaceId, meetingData: updateData)
        }
        
        private func createMeetingData(workspaceId: String, firestoreMeetingData: FirestoreMeetingData) -> Promise<MeetingData> {
            return Promise<MeetingData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingData in
                    let userList = try firestoreMeetingData.iconList.map { (iconData) -> MeetingIconData in
                        return try await(self.createMeetingUserData(firestoreMeetingIconData: iconData))
                    }
                    return MeetingData(iconList: userList, original: firestoreMeetingData)
                }).then({newWorkspaceData in
                    resolve(newWorkspaceData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        private func createMeetingUserData(firestoreMeetingIconData: FirestoreMeetingIconData) -> Promise<MeetingIconData> {
            return Promise<MeetingIconData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingIconData in
                    let iconData = firestoreMeetingIconData
                    var iconUrl: URL?
                    if let iconName = iconData.iconName {
                        iconUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                    }
                    return MeetingIconData(iconImageUrl: iconUrl, firestoreData: iconData)
                }).then({meetingIconData in
                    resolve(meetingIconData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func didChangeMeetingDataList(obj: FirestoreMeeting, documentChanges: [FirestoreDocumentChangeWithData<FirestoreMeetingData>]) {
            if let _delegate = dataListDelegate {
                async({ _ -> [RepositoryDocumentChange<MeetingData>] in
                    return try documentChanges.map { (documentChange) -> RepositoryDocumentChange<MeetingData> in
                        let meetingData = try await(self.createMeetingData(workspaceId: self.listenWorkspaceId!, firestoreMeetingData: documentChange.firestoreData))
                        return RepositoryDocumentChange<MeetingData>(documentChange: documentChange.documentChange, data: meetingData)
                    }
                }).then({ changes in
                    _delegate.didChangeMeetingDataList(obj: self, documentChanges: changes)
                }).catch { (error) in
                    SwiftyBeaver.self.error(error)
                }
            }
        }
        
        func didChangeMeetingData(obj: FirestoreMeeting, data: FirestoreMeetingData) {
            if let _delegate = dataDelegate {
                async({ _ -> MeetingData in
                    return try await(self.createMeetingData(workspaceId: self.listenWorkspaceId!, firestoreMeetingData: data))
                }).then({ meetingData in
                    _delegate.didChangeMeetingData(obj: self, data: meetingData)
                }).catch { (error) in
                    SwiftyBeaver.self.error(error)
                }
            }
        }
    }
}
