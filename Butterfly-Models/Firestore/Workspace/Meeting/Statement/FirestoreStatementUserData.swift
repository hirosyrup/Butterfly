//
//  FirestoreStatementUserData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation

struct FirestoreStatementUserData {
    var id: String
    var iconName: String?
    var name: String
    
    static func new() -> FirestoreStatementUserData {
        return FirestoreStatementUserData(id: "", iconName: nil, name: "")
    }
}
