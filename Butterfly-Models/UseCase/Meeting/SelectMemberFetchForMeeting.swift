//
//  SelectMemberFetchForMeeting.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import Hydra

class SelectMemberFetchForMeeting: SelectMemberFetchProtocol {
    private var originalUserDataList = [MeetingRepository.MeetingUserData]()
    private let workspaceId: String
    private let meetingData: MeetingRepository.MeetingData
    
    init(workspaceId: String, meetingData: MeetingRepository.MeetingData) {
        self.workspaceId = workspaceId
        self.meetingData = meetingData
    }

    func fetchMembers() -> Promise<[SelectMemberUserData]> {
        return Promise<[SelectMemberUserData]>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> [MeetingRepository.MeetingUserData] in
                return try await(MeetingRepository.User().fetchUsers(workspaceId: self.workspaceId))
            }).then({ dataList in
                self.originalUserDataList = self.mergeMeetingUserListToUserDataList(originalMeetingData: self.meetingData, userList: dataList)
                let selectMemberList = dataList.map({ (userData) -> SelectMemberUserData in
                    return SelectMemberUserData(id: userData.id, iconImageUrl: userData.iconImageUrl, name: userData.name)
                })
                resolve(selectMemberList)
            }).catch { (error) in
                reject(error)
            }
        }
    }

    func originalUserDataListAt(_ indices: [Int]) -> [MeetingRepository.MeetingUserData] {
        return indices.map { self.originalUserDataList[$0] }
    }
    
    private func mergeMeetingUserListToUserDataList(originalMeetingData: MeetingRepository.MeetingData, userList: [MeetingRepository.MeetingUserData]) -> [MeetingRepository.MeetingUserData] {
        return userList.map { (user) -> MeetingRepository.MeetingUserData in
            if let index = originalMeetingData.userList.firstIndex(where: {$0.id == user.id}) {
                return originalMeetingData.userList[index]
            } else {
                return user
            }
        }
    }
}
