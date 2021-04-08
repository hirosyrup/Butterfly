//
//  FirestoreMeetingIconData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/07.
//

import Foundation

struct FirestoreMeetingIconData {
    var userId: String
    var iconName: String?
    var name: String
    
    static func new() -> FirestoreMeetingIconData {
        return FirestoreMeetingIconData(userId: "", iconName: nil, name: "")
    }
}
