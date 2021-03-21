//
//  FirestoreDocumentChangeWithData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct FirestoreDocumentChangeWithData<T> {
    let documentChange: DocumentChange
    let firestoreData: T
}
