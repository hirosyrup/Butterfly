//
//  FirestoreUserData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation

struct FirestoreUserData {
    var id: String
    var iconName: String?
    var name: String
    var createdAt: Date
    var updatedAt: Date
    
    static func new() -> FirestoreUserData {
        return FirestoreUserData(id: "", iconName: nil, name: "Anonymous", createdAt: Date(), updatedAt: Date())
    }
    
    func copyCurrentAt() -> FirestoreUserData {
        var copied = self
        copied.updatedAt = Date()
        return copied
    }
}
