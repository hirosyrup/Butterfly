//
//  StatementViewControllerPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/30.
//

import Cocoa

class StatementViewControllerPresenter {
    private let meetingData: MeetingRepository.MeetingData
    private let meetingUserDataList: [MeetingUserRepository.MeetingUserData]
    private let you: MeetingUserRepository.MeetingUserData?
    
    init(meetingData: MeetingRepository.MeetingData, meetingUserDataList: [MeetingUserRepository.MeetingUserData], you: MeetingUserRepository.MeetingUserData?) {
        self.meetingData = meetingData
        self.meetingUserDataList = meetingUserDataList
        self.you = you
    }
    
    func title() -> String {
        return meetingData.name
    }
    
    func isHiddenRecordingLabel() -> Bool {
        if let hostIndex = meetingUserDataList.firstIndex(where: { $0.isHost }) {
            if meetingUserDataList[hostIndex].id == you?.id {
                return true
            } else {
                return !(meetingData.startedAt != nil && meetingData.endedAt == nil)
            }
        } else {
            return true
        }
    }
    
    func isHiddenOfStartButton() -> Bool {
        guard let _you = you else { return false }
        if meetingData.startedAt != nil && meetingData.endedAt != nil {
            return true
        }
        
        if let hostIndex = meetingUserDataList.firstIndex(where: { $0.isHost }) {
            return meetingUserDataList[hostIndex].id != _you.id
        } else {
            return false
        }
    }
    
    func startEndButtonState() -> NSControl.StateValue {
        if meetingData.startedAt != nil && meetingData.endedAt == nil {
            return .on
        } else {
            return .off
        }
    }
    
    func meetingMemberIconPresenters() -> [MeetingMemberIconViewPresenter] {
        return meetingUserDataList.map { StatementMemberIconViewPresenter(data: $0) }
    }
}
