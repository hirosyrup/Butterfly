//
//  FirestoreMeeting.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra

class FirestoreMeeting {
    private let db = Firestore.firestore()
    private let meetingCollectionName = "meetings"
    
    func reference(workspaceId: String) -> CollectionReference {
        return FirestoreWorkspace().reference().document(workspaceId).collection(meetingCollectionName)
    }
    
    func add(workspaceId: String, data: FirestoreMeetingData) -> Promise<FirestoreMeetingData> {
        return Promise<FirestoreMeetingData>(in: .background, token: nil) { (resolve, reject, _) in
            var ref: DocumentReference? = nil
            ref = self.reference(workspaceId: workspaceId).addDocument(data: self.meetingToFirestoreData(data: data)) { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    var newData = data
                    newData.id = ref!.documentID
                    resolve(newData)
                }
            }
        }
    }
    
    private func meetingToFirestoreData(data: FirestoreMeetingData) -> [String: Any] {
        return [
            "name": data.name,
            "userList": data.userList.map({ (user) -> [String: Any] in
                return [
                    "id": user.id,
                    "iconName": user.iconName ?? NSNull(),
                    "name": user.name
                ]
            }),
            "createdAt": Timestamp(date: data.createdAt),
            "updatedAt": Timestamp(date: data.updatedAt)
        ]
    }
    
    private func firestoreDataToMeeting(snapshot: [String: Any], meetingId: String) -> FirestoreMeetingData {
        let userRawList = (snapshot["userIdList"] as? [[String: Any]]) ?? []
        return FirestoreMeetingData(
            id: meetingId,
            name: (snapshot["name"] as? String) ?? "",
            userList: userRawList.map({ (raw) -> FirestoreMeetingUserData in
                FirestoreMeetingUserData(
                    id: (raw["id"] as? String) ?? "",
                    iconName: (raw["iconName"] as? String) ?? "",
                    name: (raw["name"] as? String) ?? ""
                )
            }),
            createdAt: (snapshot["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (snapshot["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
