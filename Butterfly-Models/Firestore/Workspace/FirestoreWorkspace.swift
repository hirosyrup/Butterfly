//
//  FirestoreWorkspace.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/20.
//

import Foundation

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra

class FirestoreWorkspace {
    private let db = Firestore.firestore()
    private let workspaceCollectionName = "workspaces"
    
    func index(userId: String) -> Promise<[FirestoreWorkspaceData]> {
        return Promise<[FirestoreWorkspaceData]>(in: .background, token: nil) { (resolve, reject, _) in
            self.db.collection(self.workspaceCollectionName).whereField("userIdList", arrayContains: userId).getDocuments { (querySnapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    let dataList = querySnapshot?.documents.map({ (snapshotDocument) -> FirestoreWorkspaceData in
                        let snapshot = snapshotDocument.data()
                        return self.firestoreDataToWorkspace(snapshot: snapshot, workspaceId: snapshotDocument.documentID)
                    })
                    resolve(dataList ?? [])
                }
            }
        }
        
    }
    
    func add(data: FirestoreWorkspaceData) -> Promise<FirestoreWorkspaceData> {
        return Promise<FirestoreWorkspaceData>(in: .background, token: nil) { (resolve, reject, _) in
            var ref: DocumentReference? = nil
            ref = self.db.collection(self.workspaceCollectionName).addDocument(data: self.workspaceToFirestoreData(data: data)) { (error) in
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
    
    func update(data: FirestoreWorkspaceData, workspaceId: String) -> Promise<FirestoreWorkspaceData> {
        return Promise<FirestoreWorkspaceData>(in: .background, token: nil) { (resolve, reject, _) in
            self.db.collection(self.workspaceCollectionName).document(workspaceId).setData(self.workspaceToFirestoreData(data: data)) { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    var newData = data
                    newData.id = workspaceId
                    resolve(newData)
                }
            }
        }
    }
    
    func fetch(workspaceId: String) -> Promise<FirestoreWorkspaceData?> {
        return Promise<FirestoreWorkspaceData?>(in: .background, token: nil) { (resolve, reject, _) in
            self.db.collection(self.workspaceCollectionName).document(workspaceId).getDocument { (snapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    if let _snapshot = snapshot, _snapshot.exists {
                        resolve(self.firestoreDataToWorkspace(snapshot: _snapshot.data() ?? [String: Any](), workspaceId: workspaceId))
                    } else {
                        resolve(nil)
                    }
                }
            }
        }
    }
    
    private func workspaceToFirestoreData(data: FirestoreWorkspaceData) -> [String: Any] {
        return [
            "name": data.name,
            "userIdList": data.userIdList,
            "createdAt": Timestamp(date: data.createdAt),
            "updatedAt": Timestamp(date: data.updatedAt)
        ]
    }
    
    private func firestoreDataToWorkspace(snapshot: [String: Any], workspaceId: String) -> FirestoreWorkspaceData {
        return FirestoreWorkspaceData(
            id: workspaceId,
            name: (snapshot["name"] as? String) ?? "",
            userIdList: (snapshot["userIdList"] as? [String]) ?? [],
            createdAt: (snapshot["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (snapshot["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
