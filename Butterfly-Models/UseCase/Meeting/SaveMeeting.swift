//
//  SaveMeeting.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import Hydra

class SaveMeeting {
    private let workspaceId: String
    private let data: MeetingRepository.MeetingData
    private let meeting = MeetingRepository.Meeting()
    
    init(workspaceId: String, data: MeetingRepository.MeetingData) {
        self.workspaceId = workspaceId
        self.data = data
    }
    
    func save() -> Promise<MeetingRepository.MeetingData> {
        return Promise<MeetingRepository.MeetingData>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> MeetingRepository.MeetingData in
                if self.data.id.isEmpty {
                    return try await(self.meeting.create(workspaceId: self.workspaceId, meetingData: self.data))
                } else {
                    return try await(self.meeting.update(workspaceId: self.workspaceId, meetingData: self.data))
                }
            }).then({ meetingData in
                resolve(meetingData)
            }).catch { (error) in
                reject(error)
            }
        }
    }
}
