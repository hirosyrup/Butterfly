//
//  FirestoreMeetingData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation

struct FirestoreMeetingData {
    var id: String
    var name: String
    var status: Int
    var startedAt: Date?
    var endedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    static func new() -> FirestoreMeetingData {
        return FirestoreMeetingData(id: "", name: "", status: 0, startedAt: nil, endedAt: nil, createdAt: Date(), updatedAt: Date())
    }
    
    func copyCurrentAt() -> FirestoreMeetingData {
        var copied = self
        copied.updatedAt = Date()
        return copied
    }
}
