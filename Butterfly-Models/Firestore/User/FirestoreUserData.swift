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
    var language: String
    var workspaceIdList: [String]
    var advancedSettingData: FirestoreUserAdvancedSettingData
    var createdAt: Date
    var updatedAt: Date
    
    static func new() -> FirestoreUserData {
        return FirestoreUserData(
            id: "",
            iconName: nil,
            name: "Anonymous",
            language: Locale.preferredLanguages.first ?? "",
            workspaceIdList: [],
            advancedSettingData: FirestoreUserAdvancedSettingData(
                enableAmiVoice: false,
                turnedOnByDefault: false,
                amiVoiceApiUrl: "",
                amiVoiceApiKey: ""
            ),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func copyCurrentAt() -> FirestoreUserData {
        var copied = self
        copied.updatedAt = Date()
        return copied
    }
}
