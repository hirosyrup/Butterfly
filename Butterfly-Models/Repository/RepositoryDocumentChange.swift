//
//  RepositoryDocumentChange.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct RepositoryDocumentChange<T> {
    let type: RepositoryDocumentChangeType
    let oldIndex: Int
    let newIndex: Int
    let data: T
    
    init(documentChange: DocumentChange, data: T) {
        let type: RepositoryDocumentChangeType
        switch documentChange.type {
        case .added:
            type = .added
        case .modified:
            type = .modified
        case .removed:
            type = .removed
        }
        self.type = type
        self.oldIndex = Int(documentChange.oldIndex)
        self.newIndex = Int(documentChange.newIndex)
        self.data = data
    }
}
