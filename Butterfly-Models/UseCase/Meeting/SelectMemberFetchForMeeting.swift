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
    
    init(workspaceId: String) {
        self.workspaceId = workspaceId
    }

    func fetchMembers() -> Promise<[SelectMemberUserData]> {
        return Promise<[SelectMemberUserData]>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> [MeetingRepository.MeetingUserData] in
                return try await(MeetingRepository.User().fetchUsers(workspaceId: self.workspaceId))
            }).then({ dataList in
                self.originalUserDataList = dataList
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
}
