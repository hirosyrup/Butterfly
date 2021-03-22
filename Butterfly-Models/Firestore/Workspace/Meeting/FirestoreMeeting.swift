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

protocol FirestoreMeetingDelegate: class {
    func didChangeMeetingData(obj: FirestoreMeeting, documentChanges: [FirestoreDocumentChangeWithData<FirestoreMeetingData>])
}

class FirestoreMeeting {
    private let db = Firestore.firestore()
    private let meetingCollectionName = "meetings"
    weak var delegate: FirestoreMeetingDelegate?
    private var workspaceListener: ListenerRegistration?
    
    func listen(workspaceId: String) {
        guard workspaceListener == nil else { return }
        workspaceListener = reference(workspaceId: workspaceId).addSnapshotListener({ (snapshot, error) in
            if let documentChanges = snapshot?.documentChanges {
                let list = documentChanges.map { (documentChange) -> FirestoreDocumentChangeWithData<FirestoreMeetingData> in
                    let data = documentChange.document.data()
                    let meetingData = self.firestoreDataToMeeting(snapshot: data, meetingId: documentChange.document.documentID)
                    return FirestoreDocumentChangeWithData(documentChange: documentChange, firestoreData: meetingData)
                }
                self.delegate?.didChangeMeetingData(obj: self, documentChanges: list)
            }
        })
    }
    
    func unlisten() {
        workspaceListener?.remove()
        workspaceListener = nil
    }
    
    func reference(workspaceId: String) -> CollectionReference {
        return FirestoreWorkspace().reference().document(workspaceId).collection(meetingCollectionName)
    }
    
    func index(workspaceId: String) -> Promise<[FirestoreMeetingData]> {
        return Promise<[FirestoreMeetingData]>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId).getDocuments(completion: { (querySnapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    let dataList = querySnapshot?.documents.map({ (snapshotDocument) -> FirestoreMeetingData in
                        let snapshot = snapshotDocument.data()
                        return self.firestoreDataToMeeting(snapshot: snapshot, meetingId: snapshotDocument.documentID)
                    })
                    resolve(dataList ?? [])
                }
            })
        }
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
    
    func update(workspaceId: String, meetingId: String, data: FirestoreMeetingData) -> Promise<FirestoreMeetingData> {
        return Promise<FirestoreMeetingData>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId).document(meetingId).setData(self.meetingToFirestoreData(data: data)) { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    var newData = data
                    newData.id = meetingId
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
        let userRawList = (snapshot["userList"] as? [[String: Any]]) ?? []
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
