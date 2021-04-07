//
//  MeetingCollectionMemberIconViewPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/07.
//

import Foundation

class MeetingCollectionMemberIconViewPresenter: MeetingMemberIconViewPresenter {
    private let data: MeetingRepository.MeetingIconData
    
    init(data: MeetingRepository.MeetingIconData) {
        self.data = data
    }
    
    func iconImageUrl() -> URL? {
        return data.iconImageUrl
    }
    
    func showEnteringIcon() -> Bool {
        return false
    }
    
    func isHost() -> Bool {
        return false
    }
}
