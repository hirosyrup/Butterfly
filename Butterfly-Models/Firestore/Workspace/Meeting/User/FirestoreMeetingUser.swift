//
//  FirestoreMeetingUser.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/06.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra

protocol FirestoreMeetingUserDataListDelegate: class {
    func didChangeMeetingUserDataList(obj: FirestoreMeetingUser, documentChanges: [FirestoreDocumentChangeWithData<FirestoreMeetingUserData>])
}

class FirestoreMeetingUser {
    private let db = Firestore.firestore()
    private let userCollectionName = "users"
    private var meetingUserListener: ListenerRegistration?
    weak var dataListDelegate: FirestoreMeetingUserDataListDelegate?
    
    func listen(workspaceId: String, meetingId: String ) {
        guard meetingUserListener == nil else { return }
        meetingUserListener = reference(workspaceId: workspaceId, meetingId: meetingId).addSnapshotListener({ (snapshot, error) in
            if let documentChanges = snapshot?.documentChanges {
                let list = documentChanges.map { (documentChange) -> FirestoreDocumentChangeWithData<FirestoreMeetingUserData> in
                    let data = documentChange.document.data()
                    let meetingUserData = self.firestoreDataToMeetingUser(snapshot: data, meetingUserId: documentChange.document.documentID)
                    return FirestoreDocumentChangeWithData(documentChange: documentChange, firestoreData: meetingUserData)
                }
                self.dataListDelegate?.didChangeMeetingUserDataList(obj: self, documentChanges: list)
            }
        })
    }
    
    func unlisten() {
        meetingUserListener?.remove()
        meetingUserListener = nil
    }
    
    func reference(workspaceId: String, meetingId: String) -> CollectionReference {
        return FirestoreMeeting().reference(workspaceId: workspaceId).document(meetingId).collection(userCollectionName)
    }
    
    func index(workspaceId: String, meetingId: String) -> Promise<[FirestoreMeetingUserData]> {
        return Promise<[FirestoreMeetingUserData]>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId, meetingId: meetingId).getDocuments(completion: { (querySnapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    let dataList = querySnapshot?.documents.map({ (snapshotDocument) -> FirestoreMeetingUserData in
                        let snapshot = snapshotDocument.data()
                        return self.firestoreDataToMeetingUser(snapshot: snapshot, meetingUserId: snapshotDocument.documentID)
                    })
                    resolve(dataList ?? [])
                }
            })
        }
    }
    
    func add(workspaceId: String, meetingId: String, data: FirestoreMeetingUserData) -> Promise<FirestoreMeetingUserData> {
        return Promise<FirestoreMeetingUserData>(in: .background, token: nil) { (resolve, reject, _) in
            var ref: DocumentReference? = nil
            ref = self.reference(workspaceId: workspaceId, meetingId: meetingId).addDocument(data: self.meetingUserToFirestoreData(data: data)) { (error) in
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
    
    func update(workspaceId: String, meetingId: String, meetingUserId: String, data: FirestoreMeetingUserData) -> Promise<FirestoreMeetingUserData> {
        return Promise<FirestoreMeetingUserData>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId, meetingId: meetingId).document(meetingUserId).setData(self.meetingUserToFirestoreData(data: data)) { (error) in
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
    
    func delete(workspaceId: String, meetingId: String, meetingUserId: String) -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference(workspaceId: workspaceId, meetingId: meetingId).document(meetingUserId).delete { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    resolve(())
                }
            }
        }
    }
    
    func deleteAll(workspaceId: String, meetingId: String) -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            do {
                let userList = try await(self.index(workspaceId: workspaceId, meetingId: meetingId))
                try userList.forEach({ (user) in
                    try await(self.delete(workspaceId: workspaceId, meetingId: meetingId, meetingUserId: user.id))
                })
                resolve(())
            } catch {
                reject(error)
            }
        }
    }
    
    private func meetingUserToFirestoreData(data: FirestoreMeetingUserData) -> [String: Any] {
        return [
            "id": data.id,
            "userId": data.userId,
            "iconName": data.iconName ?? NSNull(),
            "name": data.name,
            "isHost": data.isHost,
            "isEntering": data.isEntering,
            "audioFileName": data.audioFileName ?? NSNull(),
            "createdAt": Timestamp(date: data.createdAt),
            "updatedAt": Timestamp(date: data.updatedAt)
        ]
    }
    
    private func firestoreDataToMeetingUser(snapshot: [String: Any], meetingUserId: String) -> FirestoreMeetingUserData {
        return FirestoreMeetingUserData(
            id: meetingUserId,
            userId: (snapshot["userId"] as? String) ?? "",
            iconName: snapshot["iconName"] as? String,
            name: (snapshot["name"] as? String) ?? "",
            isHost: (snapshot["isHost"] as? Bool) ?? false,
            isEntering: (snapshot["isEntering"] as? Bool) ?? false,
            audioFileName: snapshot["audioFileName"] as? String,
            createdAt: (snapshot["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (snapshot["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
