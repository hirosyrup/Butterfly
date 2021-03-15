//
//  UserData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation

struct UserData {
    var id: String
    var iconUrl: String?
    var name: String
    var createdAt: Date
    var updatedAt: Date
    
    static func new() -> UserData {
        return UserData(id: "", iconUrl: nil, name: "Anonymous", createdAt: Date(), updatedAt: Date())
    }
    
    func copyCurrentAt() -> UserData {
        var copied = self
        copied.updatedAt = Date()
        return copied
    }
}
