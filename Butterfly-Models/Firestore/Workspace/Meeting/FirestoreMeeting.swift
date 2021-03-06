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

protocol FirestoreMeetingDataListDelegate: class {
    func didChangeMeetingDataList(obj: FirestoreMeeting, documentChanges: [FirestoreDocumentChangeWithData<FirestoreMeetingData>])
}

protocol FirestoreMeetingDataDelegate: class {
    func didChangeMeetingData(obj: FirestoreMeeting, data: FirestoreMeetingData)
}

class FirestoreMeeting {
    private let db = Firestore.firestore()
    private let meetingCollectionName = "meetings"
    weak var dataListDelegate: FirestoreMeetingDataListDelegate?
    weak var dataDelegate: FirestoreMeetingDataDelegate?
    private var workspaceListener: ListenerRegistration?
    
    func listen(workspaceId: String, startAt: Date?, endAt: Date?) {
        guard workspaceListener == nil else { return }
        var ref = referenceWithoutArchived(workspaceId: workspaceId)
        if startAt != nil {
            ref = ref.whereField("createdAt", isGreaterThan: startAt!)
        }
        if endAt != nil {
            ref = ref.whereField("createdAt", isLessThan: endAt!)
        }
        workspaceListener = ref.order(by: "createdAt", descending: true).addSnapshotListener({ (snapshot, error) in
            if let documentChanges = snapshot?.documentChanges {
                let list = documentChanges.map { (documentChange) -> FirestoreDocumentChangeWithData<FirestoreMeetingData> in
                    let data = documentChange.document.data()
                    let meetingData = self.firestoreDataToMeeting(snapshot: data, meetingId: documentChange.document.documentID)
                    return FirestoreDocumentChangeWithData(documentChange: documentChange, firestoreData: meetingData)
                }
                self.dataListDelegate?.didChangeMeetingDataList(obj: self, documentChanges: list)
            }
        })
    }
    
    func listen(workspaceId: String, meetingId: String) {
        guard workspaceListener == nil else { return }
        workspaceListener = reference(workspaceId: workspaceId).document(meetingId).addSnapshotListener({ (snapshot, error) in
            if let _snapshot = snapshot, let data = snapshot?.data() {
                self.dataDelegate?.didChangeMeetingData(obj: self, data: self.firestoreDataToMeeting(snapshot: data, meetingId: _snapshot.documentID))
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
    
    func referenceWithoutArchived(workspaceId: String) -> Query {
        return reference(workspaceId: workspaceId).whereField("status", isEqualTo: 0)
    }
    
    func index(workspaceId: String) -> Promise<[FirestoreMeetingData]> {
        return Promise<[FirestoreMeetingData]>(in: .background, token: nil) { (resolve, reject, _) in
            self.referenceWithoutArchived(workspaceId: workspaceId).getDocuments(completion: { (querySnapshot, error) in
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
    
    func fetch(workspaceId: String, meetingId: String) -> Promise<FirestoreMeetingData?> {
        return Promise<FirestoreMeetingData?>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId).document(meetingId).getDocument(completion: { (snapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    if let _snapshot = snapshot, _snapshot.exists {
                        let data = _snapshot.data()
                        resolve(self.firestoreDataToMeeting(snapshot: data ?? [String: Any](), meetingId: _snapshot.documentID))
                    } else {
                        resolve(nil)
                    }
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
            "status": data.status,
            "iconList": data.iconList.map({ (icon) -> [String: Any] in
                return [
                    "userId": icon.userId,
                    "iconName": icon.iconName ?? NSNull(),
                    "name": icon.name
                ]
            }),
            "startedAt": data.startedAt ?? NSNull(),
            "endedAt": data.endedAt ?? NSNull(),
            "createdAt": Timestamp(date: data.createdAt),
            "updatedAt": Timestamp(date: data.updatedAt)
        ]
    }
    
    private func firestoreDataToMeeting(snapshot: [String: Any], meetingId: String) -> FirestoreMeetingData {
        let iconRawList = (snapshot["iconList"] as? [[String: Any]]) ?? []
        return FirestoreMeetingData(
            id: meetingId,
            name: (snapshot["name"] as? String) ?? "",
            status: (snapshot["status"] as? Int) ?? 0,
            iconList: iconRawList.sorted(by: { ($0["userId"] as! String) > ($1["userId"] as! String) }).map({ (raw) -> FirestoreMeetingIconData in
                FirestoreMeetingIconData(
                    userId: (raw["userId"] as? String) ?? "",
                    iconName: raw["iconName"] as? String,
                    name: (raw["name"] as? String) ?? ""
                )
            }),
            startedAt: (snapshot["startedAt"] as? Timestamp)?.dateValue(),
            endedAt: (snapshot["endedAt"] as? Timestamp)?.dateValue(),
            createdAt: (snapshot["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (snapshot["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
