//
//  SearchOptionUserDefault.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/20.
//

import Foundation

class SearchOptionUserDefault {
    static let shared = SearchOptionUserDefault()
    
    let userDefault = UserDefaults.standard
    
    let dateSegmentKey = "dateSegment"
    let dateRangeStartKey = "dateRangeStart"
    let dateRangeEndKey = "dateRangeEnd"
    
    init() {
        let interval = Date().timeIntervalSince1970
        userDefault.register(defaults: [
            dateSegmentKey: 0,
            dateRangeStartKey: interval,
            dateRangeEndKey: interval
        ])
    }
    
    func saveDateSegment(segment: Int) {
        userDefault.setValue(segment, forKey: dateSegmentKey)
    }
    
    func saveDateRangeStart(date: Date) {
        let interval = date.timeIntervalSince1970
        userDefault.setValue(interval, forKey: dateRangeStartKey)
    }
    
    func saveDateRangeEnd(date: Date) {
        let interval = date.timeIntervalSince1970
        userDefault.setValue(interval, forKey: dateRangeEndKey)
    }
    
    func dateSegment() -> Int {
        userDefault.integer(forKey: dateSegmentKey)
    }
    
    func dateRangeStart() -> Date {
        let interval = userDefault.double(forKey: dateRangeStartKey)
        return Date(timeIntervalSince1970: interval)
    }
    
    func dateRangeEnd() -> Date {
        let interval = userDefault.double(forKey: dateRangeEndKey)
        return Date(timeIntervalSince1970: interval)
    }
}
