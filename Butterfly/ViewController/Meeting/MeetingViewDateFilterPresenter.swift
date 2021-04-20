//
//  MeetingViewDateFilterPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/21.
//

import Foundation

class MeetingViewDateFilterPresenter {
    private let userDefault: SearchOptionUserDefault
    
    init(userDefault: SearchOptionUserDefault) {
        self.userDefault = userDefault
    }
    
    func dateFilterLabel() -> String {
        let segment = userDefault.dateSegment()
        if segment == 0 {
            return "No filtering by date."
        }
        
        let start = userDefault.dateRangeStart()
        let end = userDefault.dateRangeEnd()
        let dateFormatter = DateFormatter()
        if let id = Locale.preferredLanguages.first {
            dateFormatter.locale = Locale(identifier: id)
        }
        dateFormatter.dateStyle = .medium
        return "\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end))"
    }
}
