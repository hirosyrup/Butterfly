//
//  MeetingCollectionViewItemPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation

class MeetingCollectionViewItemPresenter {
    private let data: MeetingRepository.MeetingData
    
    init(data: MeetingRepository.MeetingData) {
        self.data = data
    }
    
    func title() -> String {
        return data.name
    }
    
    func createdAt() -> String {
        let language = Locale.preferredLanguages.first
        let f = DateFormatter()
        f.timeStyle = .none
        f.dateStyle = .full
        f.locale = language == nil ? Locale.current : Locale(identifier: language!)
        return f.string(from: data.createdAt)
    }
    
    func meetingMemberIconViewPresenters() -> [MeetingMemberIconViewPresenter] {
        return data.iconList.map { MeetingCollectionMemberIconViewPresenter(data: $0) }
    }
}
