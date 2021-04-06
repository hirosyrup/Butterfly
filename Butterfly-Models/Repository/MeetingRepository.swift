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

protocol MeetingRepositoryUserDataListDelegate: class {
    func didChangeMeetingUserDataList(obj: MeetingRepository.Meeting, documentChanges: [RepositoryDocumentChange<MeetingRepository.MeetingUserData>])
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
        var userList: [MeetingUserData]
        
        init(userList: [MeetingUserData], original: FirestoreMeetingData? = nil) {
            self.userList = userList
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
            return firestoreData
        }
        
        fileprivate func toFirestoreMeetingUserDataList() -> [FirestoreMeetingUserData] {
            return userList.map { $0.toFirestoreData() }
        }
    }
    
    struct MeetingUserData {
        let id: String
        let iconName: String?
        let iconImageUrl: URL?
        let name: String
        var isHost: Bool
        var isEntering: Bool
        var audioFileName: String?
        
        init(iconImageUrl: URL?, firestoreData: FirestoreMeetingUserData) {
            self.iconImageUrl = iconImageUrl
            self.id = firestoreData.id
            self.iconName = firestoreData.iconName
            self.name = firestoreData.name
            self.isHost = firestoreData.isHost
            self.isEntering = firestoreData.isEntering
            self.audioFileName = firestoreData.audioFileName
        }
        
        init(iconImageUrl: URL?, firestoreData: FirestoreUserData) {
            self.iconImageUrl = iconImageUrl
            self.id = firestoreData.id
            self.iconName = firestoreData.iconName
            self.name = firestoreData.name
            self.isHost = false
            self.isEntering = false
            self.audioFileName = nil
        }
        
        fileprivate func toFirestoreData() -> FirestoreMeetingUserData {
            return FirestoreMeetingUserData(id: id, iconName: iconName, name: name, isHost: isHost, isEntering: isEntering, audioFileName: audioFileName)
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
    
    class Meeting: FirestoreMeetingDataListDelegate, FirestoreMeetingDataDelegate, FirestoreMeetingUserDataListDelegate {
        private let meeting = FirestoreMeeting()
        private let meetingUser = FirestoreMeetingUser()
        private let iconImage = IconImage.shared
        private weak var dataListDelegate: MeetingRepositoryDataListDelegate?
        private weak var dataDelegate: MeetingRepositoryDataDelegate?
        private weak var userDataListDelegate: MeetingRepositoryUserDataListDelegate?
        private(set) var listenWorkspaceId: String?
        
        init() {
            meeting.dataListDelegate = self
            meeting.dataDelegate = self
            meetingUser.dataListDelegate = self
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
        
        func listenUserData(workspaceId: String, meetingId: String, dataListDelegate: MeetingRepositoryUserDataListDelegate) {
            self.userDataListDelegate = dataListDelegate
            listenWorkspaceId = workspaceId
            meetingUser.listen(workspaceId: workspaceId, meetingId: meetingId)
        }
        
        func unlisten() {
            dataListDelegate = nil
            dataDelegate = nil
            userDataListDelegate = nil
            listenWorkspaceId = nil
            meeting.unlisten()
            meetingUser.unlisten()
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
                    let createdFirestoreMeetingUserDataList = try meetingData.toFirestoreMeetingUserDataList().map({ (user) -> FirestoreMeetingUserData in
                        return try await(self.meetingUser.add(workspaceId: workspaceId, meetingId: meetingData.id, data: user))
                    })
                    return try await(self.createMeetingData(workspaceId: workspaceId, firestoreMeetingData: createdFirestoreMeetingData, firestoreMeetingUserDataList: createdFirestoreMeetingUserDataList))
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
                    try await(self.meetingUser.deleteAll(workspaceId: workspaceId, meetingId: meetingData.id))
                    let savedFirestoreMeetingUserDataList = try meetingData.toFirestoreMeetingUserDataList().map({ (user) -> FirestoreMeetingUserData in
                        return try await(self.meetingUser.add(workspaceId: workspaceId, meetingId: meetingData.id, data: user))
                    })
                    return try await(self.createMeetingData(workspaceId: workspaceId, firestoreMeetingData: savedFirestoreMeetingData, firestoreMeetingUserDataList: savedFirestoreMeetingUserDataList))
                }).then({newMeetingData in
                    resolve(newMeetingData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func updateUser(workspaceId: String, meetingData: MeetingData, userIndex: Int) -> Promise<MeetingUserData> {
            return Promise<MeetingUserData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingUserData in
                    let meetingId = meetingData.original.id
                    let firestoreMeetingData = meetingData.toFirestoreData().copyCurrentAt()
                    let _ = try await(self.meeting.update(workspaceId: workspaceId, meetingId: meetingId, data: firestoreMeetingData))
                    let userData = meetingData.userList[userIndex]
                    let firestoreMeetingUserData = try await(self.meetingUser.update(workspaceId: workspaceId, meetingId: meetingData.id, meetingUserId: userData.id, data: userData.toFirestoreData()))
                    return try await(self.createMeetingUserData(firestoreMeetingUserData: firestoreMeetingUserData))
                }).then({newMeetingUserData in
                    resolve(newMeetingUserData)
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
        
        func createMeetingUserDataListFromDocumentChanges(prevUserDataList: [MeetingUserData], documentChanges: [RepositoryDocumentChange<MeetingUserData>]) -> [MeetingUserData] {
            var dataList = prevUserDataList
            let modifieds = documentChanges.filter { $0.type == .modified }
            modifieds.forEach { (modified) in
                if let index = dataList.firstIndex(where: { $0.id == modified.data.id }) {
                    dataList[index] = modified.data
                }
            }
            
            let removesIds = documentChanges.filter { $0.type == .removed }.map { $0.data.id }
            var removedUserDataList = [MeetingUserData]()
            dataList.forEach {
                if !removesIds.contains($0.id) {
                    removedUserDataList.append($0)
                }
            }
            dataList = removedUserDataList
            
            let addeds = documentChanges.filter { $0.type == .added }
            addeds.forEach { (addedChange) in
                if addedChange.newIndex >= dataList.count {
                    dataList.append(addedChange.data)
                } else {
                    dataList.insert(addedChange.data, at: addedChange.newIndex)
                }
            }
            
            return dataList
        }
        
        private func createMeetingData(workspaceId: String, firestoreMeetingData: FirestoreMeetingData, firestoreMeetingUserDataList: [FirestoreMeetingUserData]? = nil) -> Promise<MeetingData> {
            return Promise<MeetingData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingData in
                    let userList = firestoreMeetingUserDataList != nil ? firestoreMeetingUserDataList! :  try await(self.meetingUser.index(workspaceId: workspaceId, meetingId: firestoreMeetingData.id))
                    let meetingUserDataList = try userList.map { (user) -> MeetingUserData in
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
        
        private func createMeetingUserData(firestoreMeetingUserData: FirestoreMeetingUserData) -> Promise<MeetingUserData> {
            return Promise<MeetingUserData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingUserData in
                    let user = firestoreMeetingUserData
                    var iconUrl: URL?
                    if let iconName = user.iconName {
                        iconUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                    }
                    return MeetingUserData(iconImageUrl: iconUrl, firestoreData: user)
                }).then({meetingUserData in
                    resolve(meetingUserData)
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
        
        func didChangeMeetingUserDataList(obj: FirestoreMeetingUser, documentChanges: [FirestoreDocumentChangeWithData<FirestoreMeetingUserData>]) {
            if let _delegate = userDataListDelegate {
                async({ _ -> [RepositoryDocumentChange<MeetingUserData>] in
                    return try documentChanges.map { (documentChange) -> RepositoryDocumentChange<MeetingUserData> in
                        let meetingUserData = try await(self.createMeetingUserData(firestoreMeetingUserData: documentChange.firestoreData))
                        return RepositoryDocumentChange<MeetingUserData>(documentChange: documentChange.documentChange, data: meetingUserData)
                    }
                }).then({ changes in
                    _delegate.didChangeMeetingUserDataList(obj: self, documentChanges: changes)
                }).catch { (error) in
                    SwiftyBeaver.self.error(error)
                }
            }
        }
    }
}
