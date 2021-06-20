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
                return !meetingData.isInMeeting()
            }
        } else {
            return true
        }
    }
    
    func isHiddenOfStartButton() -> Bool {
        guard let _you = you else { return true }
        if meetingData.isFinished() {
            return true
        }
        
        if let hostIndex = meetingUserDataList.firstIndex(where: { $0.isHost }) {
            return meetingUserDataList[hostIndex].id != _you.id
        } else {
            return false
        }
    }
    
    func isHiddenOfShowCollectionButton() -> Bool {
        return meetingData.isFinished()
    }
    
    func isHiddenSwitchOptionButton() -> Bool {
        return meetingData.isFinished()
    }
    
    func startEndButtonState() -> NSControl.StateValue {
        if meetingData.isInMeeting() {
            return .on
        } else {
            return .off
        }
    }
    
    func meetingMemberIconPresenters() -> [MeetingMemberIconViewPresenter] {
        return meetingUserDataList.map { StatementMemberIconViewPresenter(data: $0) }
    }
    
    func isHiddenLevelMeter() -> Bool {
        return meetingData.isFinished()
    }
    
    func isHiddenSearchField() -> Bool {
        return !meetingData.isFinished()
    }
}
