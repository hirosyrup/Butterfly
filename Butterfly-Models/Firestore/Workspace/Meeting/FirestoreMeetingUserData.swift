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
    
    static func new() -> FirestoreMeetingUserData {
        return FirestoreMeetingUserData(id: "", iconName: nil, name: "")
    }
}