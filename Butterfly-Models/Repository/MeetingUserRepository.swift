//
//  MeetingUserRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/07.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra
import SwiftyBeaver

protocol MeetingUserRepositoryDataListDelegate: class {
    func didChangeMeetingUserDataList(obj: MeetingUserRepository.User, documentChanges: [RepositoryDocumentChange<MeetingUserRepository.MeetingUserData>])
}

class MeetingUserRepository {
    struct MeetingUserData {
        fileprivate let original: FirestoreMeetingUserData
        let id: String
        let userId: String
        let iconName: String?
        let iconImageUrl: URL?
        let name: String
        var isHost: Bool
        var isEntering: Bool
        var audioFileName: String?
        
        init(iconImageUrl: URL?, firestoreData: FirestoreMeetingUserData) {
            self.original = firestoreData
            self.id = self.original.id
            self.userId = self.original.userId
            self.iconName = self.original.iconName
            self.iconImageUrl = iconImageUrl
            self.name = self.original.name
            self.isHost = self.original.isHost
            self.isEntering = self.original.isEntering
            self.audioFileName = self.original.audioFileName
        }
        
        fileprivate func toFirestoreData() -> FirestoreMeetingUserData {
            var firestoreData = original
            firestoreData.userId = userId
            firestoreData.iconName = iconName
            firestoreData.name = name
            firestoreData.isHost = isHost
            firestoreData.isEntering = isEntering
            firestoreData.audioFileName = audioFileName
            return firestoreData
        }
    }
    
    class User: FirestoreMeetingUserDataListDelegate {
        private let meetingUser = FirestoreMeetingUser()
        private let iconImage = IconImage.shared
        private let audioStorage = AudioStorage()
        private weak var dataListDelegate: MeetingUserRepositoryDataListDelegate?
        private(set) var listenWorkspaceId: String?
        
        init() {
            meetingUser.dataListDelegate = self
        }
        
        func listen(workspaceId: String, meetingId: String, dataListDelegate: MeetingUserRepositoryDataListDelegate) {
            self.dataListDelegate = dataListDelegate
            listenWorkspaceId = workspaceId
            meetingUser.listen(workspaceId: workspaceId, meetingId: meetingId)
        }
        
        func unlisten() {
            meetingUser.dataListDelegate = nil
            meetingUser.unlisten()
        }
        
        func index(workspaceId: String, meetingId: String) -> Promise<[MeetingUserData]> {
            return Promise<[MeetingUserData]>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> [MeetingUserData] in
                    let firestoreMeetingUserDataList = try await(self.meetingUser.index(workspaceId: workspaceId, meetingId: meetingId))
                    return try firestoreMeetingUserDataList.map { (firestoreMeetingUserData) -> MeetingUserData in
                        return try await(self.createMeetingUserData(workspaceId: workspaceId, firestoreMeetingUserData: firestoreMeetingUserData))
                    }
                }).then({ meetingUserDataList in
                    resolve(meetingUserDataList)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func update(workspaceId: String, meetingId: String, meetingUserData: MeetingUserData) -> Promise<MeetingUserData> {
            return Promise<MeetingUserData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingUserData in
                    let meetingUserId = meetingUserData.original.id
                    let firestoreMeetingUserData = meetingUserData.toFirestoreData().copyCurrentAt()
                    let savedFirestoreMeetingData = try await(self.meetingUser.update(workspaceId: workspaceId, meetingId: meetingId, meetingUserId: meetingUserId, data: firestoreMeetingUserData))
                    return try await(self.createMeetingUserData(workspaceId: workspaceId, firestoreMeetingUserData: savedFirestoreMeetingData))
                }).then({meetingUserData in
                    resolve(meetingUserData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func createUserListFromDocumentChanges(prevUserList: [MeetingUserData], documentChanges: [RepositoryDocumentChange<MeetingUserData>]) -> [MeetingUserData] {
            var userList = prevUserList
            let modifieds = documentChanges.filter { $0.type == .modified }
            modifieds.forEach { (modified) in
                if let index = userList.firstIndex(where: { $0.id == modified.data.id }) {
                    userList[index] = modified.data
                }
            }
            
            let removesIds = documentChanges.filter { $0.type == .removed }.map { $0.data.id }
            var removedUserList = [MeetingUserData]()
            userList.forEach {
                if !removesIds.contains($0.id) {
                    removedUserList.append($0)
                }
            }
            userList = removedUserList
            
            let addeds = documentChanges.filter { $0.type == .added }
            addeds.forEach { (addedChange) in
                if addedChange.newIndex >= userList.count {
                    userList.append(addedChange.data)
                } else {
                    userList.insert(addedChange.data, at: addedChange.newIndex)
                }
            }
            
            return userList
        }
        
        private func createMeetingUserData(workspaceId: String, firestoreMeetingUserData: FirestoreMeetingUserData) -> Promise<MeetingUserData> {
            return Promise<MeetingUserData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> MeetingUserData in
                    let iconUrl = firestoreMeetingUserData.iconName == nil ? nil : try await(self.iconImage.fetchDownloadUrl(fileName: firestoreMeetingUserData.iconName!))
                    return MeetingUserData(iconImageUrl: iconUrl, firestoreData: firestoreMeetingUserData)
                }).then({newMeetingUserData in
                    resolve(newMeetingUserData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func didChangeMeetingUserDataList(obj: FirestoreMeetingUser, documentChanges: [FirestoreDocumentChangeWithData<FirestoreMeetingUserData>]) {
            if let _delegate = dataListDelegate {
                async({ _ -> [RepositoryDocumentChange<MeetingUserData>] in
                    return try documentChanges.map { (documentChange) -> RepositoryDocumentChange<MeetingUserData> in
                        let meetingUserData = try await(self.createMeetingUserData(workspaceId: self.listenWorkspaceId!, firestoreMeetingUserData: documentChange.firestoreData))
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
