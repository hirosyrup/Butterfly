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
    private let userId: String
    private let db = Firestore.firestore()
    private let userCollectionName = "users"
    
    init(userId: String) {
        self.userId = userId
    }
    
    func save(data: UserData) -> Promise<UserData> {
        return Promise<UserData>(in: .background, token: nil) { (resolve, reject, _) in
            self.db.collection(self.userCollectionName).document(self.userId).setData(self.userToFirestoreData(data: data)) { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    var newData = data
                    newData.id = self.userId
                    resolve(newData)
                }
            }
        }
    }
    
    func fetch() -> Promise<UserData?> {
        return Promise<UserData?>(in: .background, token: nil) { (resolve, reject, _) in
            self.db.collection(self.userCollectionName).document(self.userId).getDocument { (snapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    if let _snapshot = snapshot, _snapshot.exists {
                        resolve(self.firestoreDataToUser(snapshot: _snapshot.data() ?? [String: Any]()))
                    } else {
                        resolve(nil)
                    }
                }
            }
        }
    }
    
    private func userToFirestoreData(data: UserData) -> [String: Any] {
        return [
            "iconName": data.iconName ?? NSNull(),
            "name": data.name,
            "createdAt": Timestamp(date: data.createdAt),
            "updatedAt": Timestamp(date: data.updatedAt)
        ]
    }
    
    private func firestoreDataToUser(snapshot: [String: Any]) -> UserData {
        return UserData(
            id: userId,
            iconName: snapshot["iconName"] as? String,
            name: (snapshot["name"] as? String) ?? "",
            createdAt: (snapshot["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (snapshot["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
