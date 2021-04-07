//
//  StatementMemberIconViewPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/07.
//

import Foundation

class StatementMemberIconViewPresenter: MeetingMemberIconViewPresenter {
    private let data: MeetingUserRepository.MeetingUserData
    
    init(data: MeetingUserRepository.MeetingUserData) {
        self.data = data
    }
    
    func iconImageUrl() -> URL? {
        return data.iconImageUrl
    }
    
    func showEnteringIcon() -> Bool {
        return data.isEntering
    }
    
    func isHost() -> Bool {
        return data.isHost
    }
}
