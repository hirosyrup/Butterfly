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
