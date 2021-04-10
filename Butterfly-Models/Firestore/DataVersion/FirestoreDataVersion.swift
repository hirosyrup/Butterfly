//
//  FirestoreDataVersion.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/10.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra

class FirestoreDataVersion {
    private let db = Firestore.firestore()
    private let dataVersionDocumentName = "dataVersion"
    
    func reference() -> DocumentReference {
        return db.collection(dataVersionDocumentName).document("1")
    }
    
    func update(data: FirestoreDataVersionData) -> Promise<FirestoreDataVersionData> {
        return Promise<FirestoreDataVersionData>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference().setData(self.dataVersionToFirestoreData(data: data)) { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    resolve(data)
                }
            }
        }
    }
    
    func fetch() -> Promise<FirestoreDataVersionData> {
        return Promise<FirestoreDataVersionData>(in: .background, token: nil) { (resolve, reject, _) in
            self.reference().getDocument { (snapshot, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    resolve(self.firestoreDataToDataVersion(snapshot: snapshot?.data() ?? [String: Any]()))
                }
            }
        }
    }
    
    private func dataVersionToFirestoreData(data: FirestoreDataVersionData) -> [String: Any] {
        return [
            "version": data.version
        ]
    }
    
    private func firestoreDataToDataVersion(snapshot: [String: Any]) -> FirestoreDataVersionData {
        return FirestoreDataVersionData(
            version: (snapshot["version"] as? Int) ?? 0
        )
    }
}
