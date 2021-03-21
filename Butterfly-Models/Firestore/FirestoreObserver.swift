//
//  FirestoreObserver.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol FirestoreWorkspaceNotification: class {
    func didChangeWorkspaceData(observer: FirestoreObserver)
}

class FirestoreObserver {
    static let shared = FirestoreObserver()
    private var workspaceObservers = [FirestoreWorkspaceNotification]()
    private var workspaceListener: ListenerRegistration?
    private var currentListenUserId = ""
    
    func addWorkspaceObserver(observer: FirestoreWorkspaceNotification) {
        if workspaceObservers.firstIndex(where: { $0 === observer }) == nil {
            workspaceObservers.append(observer)
        }
    }
    
    func removeWorkspaceObserver(observer: FirestoreWorkspaceNotification) {
        if let index = workspaceObservers.firstIndex(where: { $0 === observer }) {
            workspaceObservers.remove(at: index)
        }
    }
    
    func listenWorkspace() {
        guard workspaceListener == nil else { return }
        workspaceListener = FirestoreWorkspace().reference().addSnapshotListener { (_, error) in
            if error == nil {
                self.notifyDidChangeWorkspaceData()
            }
        }
    }
    
    func unlistenWorkspace() {
        workspaceListener?.remove()
        workspaceListener = nil
    }
    
    private func notifyDidChangeWorkspaceData() {
        workspaceObservers.forEach { $0.didChangeWorkspaceData(observer: self) }
    }
}
