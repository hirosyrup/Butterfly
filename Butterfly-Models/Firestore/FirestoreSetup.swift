//
//  FirestoreSetup.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/11.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Hydra

class FirestoreSetup {
    private let currentDataVersion = 1
    private let url: URL?
    private var completion: ((Bool) -> Void)?
    
    init() {
        self.url = SettingUserDefault().firebasePlistUrl()
    }
    
    func setup(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        guard let path = url?.path.removingPercentEncoding else {
            self.completion?(false)
            self.completion = nil
            return
        }
        if let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(options: options)
            Firestore.firestore().settings = FirestoreSettings()
            AuthUser.shared.listenAuthEvent()
            if AuthUser.shared.isSignIn() {
                FirestoreObserver.shared.listenWorkspace()
            }
            async({ _ -> FirestoreDataVersionData in
                let firestoreDataVersion = FirestoreDataVersion()
                var data = try await(firestoreDataVersion.fetch())
                if data.version >= self.currentDataVersion {
                    return data
                } else {
                    data.version = self.currentDataVersion
                    return try await(firestoreDataVersion.update(data: data))
                }
            }).then({data in
                var needUpdate = false
                if data.version > self.currentDataVersion {
                    needUpdate = true
                }
                self.completion?(needUpdate)
                self.completion = nil
            }).catch { (_) in
                self.completion?(false)
                self.completion = nil
            }
        }
    }
    
    func isConfigured() -> Bool {
        return FirebaseApp.app() != nil
    }
}
