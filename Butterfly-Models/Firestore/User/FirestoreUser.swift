//
//  FirestoreUser.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra

class FirestoreUser {
    private let db = Firestore.firestore()
    private let userCollectionName = "users"
    
    func index(userIdList: [String] = []) -> Promise<[FirestoreUserData]> {
        return Promise<[FirestoreUserData]>(in: .background, token: nil) { (resolve, reject, _) in
            var reference = self.db.collection(self.userCollectionName) as Query
            if !userIdList.isEmpty {
                reference = reference.whereField(FieldPath.documentID(), in: userIdList)
            }
            reference.getDocuments { (querySnapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    let dataList = querySnapshot?.documents.map({ (snapshotDocument) -> FirestoreUserData in
                        let snapshot = snapshotDocument.data()
                        return self.firestoreDataToUser(snapshot: snapshot, userId: snapshotDocument.documentID)
                    })
                    resolve(dataList ?? [])
                }
            }
        }
        
    }
    
    func save(data: FirestoreUserData, userId: String) -> Promise<FirestoreUserData> {
        return Promise<FirestoreUserData>(in: .background, token: nil) { (resolve, reject, _) in
            self.db.collection(self.userCollectionName).document(userId).setData(self.userToFirestoreData(data: data)) { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    var newData = data
                    newData.id = userId
                    resolve(newData)
                }
            }
        }
    }
    
    func fetch(userId: String) -> Promise<FirestoreUserData?> {
        return Promise<FirestoreUserData?>(in: .background, token: nil) { (resolve, reject, _) in
            self.db.collection(self.userCollectionName).document(userId).getDocument { (snapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    if let _snapshot = snapshot, _snapshot.exists {
                        resolve(self.firestoreDataToUser(snapshot: _snapshot.data() ?? [String: Any](), userId: userId))
                    } else {
                        resolve(nil)
                    }
                }
            }
        }
    }
    
    private func userToFirestoreData(data: FirestoreUserData) -> [String: Any] {
        return [
            "iconName": data.iconName ?? NSNull(),
            "name": data.name,
            "workspaceIdList": data.workspaceIdList,
            "advancedSettingData": [
                "enableAmiVoice": data.advancedSettingData.enableAmiVoice,
                "turnedOnByDefault": data.advancedSettingData.turnedOnByDefault,
                "amiVoiceApiUrl": data.advancedSettingData.amiVoiceApiUrl,
                "amiVoiceApiKey": data.advancedSettingData.amiVoiceApiKey
            ],
            "createdAt": Timestamp(date: data.createdAt),
            "updatedAt": Timestamp(date: data.updatedAt)
        ]
    }
    
    private func firestoreDataToUser(snapshot: [String: Any], userId: String) -> FirestoreUserData {
        let advancedSettingData = (snapshot["advancedSettingData"] as? [String: Any]) ?? [:]
        return FirestoreUserData(
            id: userId,
            iconName: snapshot["iconName"] as? String,
            name: (snapshot["name"] as? String) ?? "",
            workspaceIdList: (snapshot["workspaceIdList"] as? [String]) ?? [],
            advancedSettingData: FirestoreUserAdvancedSettingData(
                enableAmiVoice: (advancedSettingData["enableAmiVoice"] as? Bool) ?? false,
                turnedOnByDefault: (advancedSettingData["turnedOnByDefault"] as? Bool) ?? false,
                amiVoiceApiUrl: (advancedSettingData["amiVoiceApiUrl"] as? String) ?? "",
                amiVoiceApiKey: (advancedSettingData["amiVoiceApiKey"] as? String) ?? ""
            ),
            createdAt: (snapshot["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (snapshot["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
