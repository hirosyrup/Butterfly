//
//  StatementViewControllerPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/30.
//

import Cocoa

class StatementViewControllerPresenter {
    private let meetingData: MeetingRepository.MeetingData
    private let you: MeetingRepository.MeetingUserData?
    
    init(meetingData: MeetingRepository.MeetingData, you: MeetingRepository.MeetingUserData?) {
        self.meetingData = meetingData
        self.you = you
    }
    
    func title() -> String {
        return meetingData.name
    }
    
    func isHiddenRecordingLabel() -> Bool {
        if let hostIndex = meetingData.userList.firstIndex(where: { $0.isHost }) {
            if meetingData.userList[hostIndex].id == you?.id {
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
        
        if let hostIndex = meetingData.userList.firstIndex(where: { $0.isHost }) {
            return meetingData.userList[hostIndex].id != _you.id
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
        return meetingData.userList.map { MeetingMemberIconViewPresenter(data: $0) }
    }
}
