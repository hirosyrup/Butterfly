//
//  MeetingMemberIconViewPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/28.
//

import Foundation

class MeetingMemberIconViewPresenter {
    private let data: MeetingRepository.MeetingUserData
    
    init(data: MeetingRepository.MeetingUserData) {
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
