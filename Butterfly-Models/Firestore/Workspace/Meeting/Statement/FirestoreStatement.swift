//
//  FirestoreStatement.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra

protocol FirestoreStatementDelegate: class {
    func didChangeStatementData(obj: FirestoreStatement, documentChanges: [FirestoreDocumentChangeWithData<FirestoreStatementData>])
}

class FirestoreStatement {
    private let db = Firestore.firestore()
    private let statementCollectionName = "statements"
    weak var delegate: FirestoreStatementDelegate?
    private var statementListener: ListenerRegistration?
    
    func listen(workspaceId: String, meetingId: String) {
        guard statementListener == nil else { return }
        statementListener = reference(workspaceId: workspaceId, meetingId: meetingId).order(by: "createdAt").addSnapshotListener({ (snapshot, error) in
            if let documentChanges = snapshot?.documentChanges {
                let list = documentChanges.map { (documentChange) -> FirestoreDocumentChangeWithData<FirestoreStatementData> in
                    let data = documentChange.document.data()
                    let statementData = self.firestoreDataToStatement(snapshot: data, statementId: documentChange.document.documentID)
                    return FirestoreDocumentChangeWithData(documentChange: documentChange, firestoreData: statementData)
                }
                self.delegate?.didChangeStatementData(obj: self, documentChanges: list)
            }
        })
    }
    
    func unlisten() {
        statementListener?.remove()
        statementListener = nil
    }
    
    func reference(workspaceId: String, meetingId: String) -> CollectionReference {
        return FirestoreMeeting().reference(workspaceId: workspaceId).document(meetingId).collection(statementCollectionName)
    }
    
    func index(workspaceId: String, meetingId: String) -> Promise<[FirestoreStatementData]> {
        return Promise<[FirestoreStatementData]>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId, meetingId: meetingId).getDocuments(completion: { (querySnapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    let dataList = querySnapshot?.documents.map({ (snapshotDocument) -> FirestoreStatementData in
                        let snapshot = snapshotDocument.data()
                        return self.firestoreDataToStatement(snapshot: snapshot, statementId: snapshotDocument.documentID)
                    })
                    resolve(dataList ?? [])
                }
            })
        }
    }
    
    func add(workspaceId: String, meetingId: String, data: FirestoreStatementData) -> Promise<FirestoreStatementData> {
        return Promise<FirestoreStatementData>(in: .background, token: nil) { (resolve, reject, _) in
            var ref: DocumentReference? = nil
            ref = self.reference(workspaceId: workspaceId, meetingId: meetingId).addDocument(data: self.statementToFirestoreData(data: data)) { (error) in
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
    
    func update(workspaceId: String, meetingId: String, statementId: String, data: FirestoreStatementData) -> Promise<FirestoreStatementData> {
        return Promise<FirestoreStatementData>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId, meetingId: meetingId).document(statementId).setData(self.statementToFirestoreData(data: data)) { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    var newData = data
                    newData.id = statementId
                    resolve(newData)
                }
            }
        }
    }
    
    func delete(workspaceId: String, meetingId: String, statementId: String) -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId, meetingId: meetingId).document(statementId).delete { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    resolve(())
                }
            }
        }
    }
    
    private func statementToFirestoreData(data: FirestoreStatementData) -> [String: Any] {
        return [
            "statement": data.statement,
            "user": [
                "id": data.user.id,
                "iconName": data.user.iconName ?? NSNull(),
                "name": data.user.name
            ] as [String: Any],
            "createdAt": Timestamp(date: data.createdAt),
            "updatedAt": Timestamp(date: data.updatedAt)
        ]
    }
    
    private func firestoreDataToStatement(snapshot: [String: Any], statementId: String) -> FirestoreStatementData {
        let userRaw = (snapshot["user"] as? [String: Any]) ?? [String: Any]()
        return FirestoreStatementData(
            id: statementId,
            statement: (snapshot["statement"] as? String) ?? "",
            user: FirestoreStatementUserData(
                id: (userRaw["id"] as? String) ?? "",
                iconName: userRaw["iconName"] as? String,
                name: (userRaw["name"] as? String) ?? ""
            ),
            createdAt: (snapshot["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (snapshot["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
