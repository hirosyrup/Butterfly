//
//  SelectMemberFetchForMeeting.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import Hydra

class SelectMemberFetchForMeeting: SelectMemberFetchProtocol {
    private var originalUserDataList = [MeetingRepository.MeetingIconData]()
    private let workspaceId: String
    private let meetingData: MeetingRepository.MeetingData
    
    init(workspaceId: String, meetingData: MeetingRepository.MeetingData) {
        self.workspaceId = workspaceId
        self.meetingData = meetingData
    }

    func fetchMembers() -> Promise<[SelectMemberUserData]> {
        return Promise<[SelectMemberUserData]>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> [MeetingRepository.MeetingIconData] in
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

    func originalUserDataListAt(_ indices: [Int]) -> [MeetingRepository.MeetingIconData] {
        return indices.map { self.originalUserDataList[$0] }
    }
    
    private func mergeMeetingUserListToUserDataList(originalMeetingData: MeetingRepository.MeetingData, userList: [MeetingRepository.MeetingIconData]) -> [MeetingRepository.MeetingIconData] {
        return userList.map { (user) -> MeetingRepository.MeetingIconData in
            if let index = originalMeetingData.iconList.firstIndex(where: {$0.id == user.id}) {
                return originalMeetingData.iconList[index]
            } else {
                return user
            }
        }
    }
}
