//
//  FirestoreStatementData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation

struct FirestoreStatementData {
    var id: String
    var statement: String
    var user: FirestoreStatementUserData
    var createdAt: Date
    var updatedAt: Date
    
    static func new() -> FirestoreStatementData {
        return FirestoreStatementData(id: "", statement: "", user:FirestoreStatementUserData.new(), createdAt: Date(), updatedAt: Date())
    }
    
    func copyCurrentAt() -> FirestoreStatementData {
        var copied = self
        copied.updatedAt = Date()
        return copied
    }
}
