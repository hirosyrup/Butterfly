//
//  FirestoreMeetingUserData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation

struct FirestoreMeetingUserData {
    var id: String
    var iconName: String?
    var name: String
    var isHost: Bool
    var isEntering: Bool
    var audioFileName: String?
    var createdAt: Date
    var updatedAt: Date
    
    static func new() -> FirestoreMeetingUserData {
        return FirestoreMeetingUserData(id: "", iconName: nil, name: "", isHost: false, isEntering: false, audioFileName: nil, createdAt: Date(), updatedAt: Date())
    }
    
    func copyCurrentAt() -> FirestoreMeetingUserData {
        var copied = self
        copied.updatedAt = Date()
        return copied
    }
}
