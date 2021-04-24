//
//  FirestoreWorkspaceData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/20.
//

import Foundation

struct FirestoreWorkspaceData {
    var id: String
    var name: String
    var userIdList: [String]
    var isEnableSpeakerRecognition: Bool
    var mlFileName: String?
    var createdAt: Date
    var updatedAt: Date
    
    static func new() -> FirestoreWorkspaceData {
        return FirestoreWorkspaceData(
            id: "",
            name: "",
            userIdList: [],
            isEnableSpeakerRecognition: false,
            mlFileName: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func copyCurrentAt() -> FirestoreWorkspaceData {
        var copied = self
        copied.updatedAt = Date()
        return copied
    }
}
