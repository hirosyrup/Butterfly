//
//  Auth.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/15.
//

import Foundation
import FirebaseAuth

protocol AuthUserNotification: class {
    func didUpdateUser(authUser: AuthUser)
}

class AuthUser {
    static let shared = AuthUser()
    
    private var listener: AuthStateDidChangeListenerHandle?
    
    private var observers = [AuthUserNotification]()
    
    func listenAuthEvent() {
        listener = Auth.auth().addStateDidChangeListener { (_, _) in
            self.notifyDidUpdateUser()
        }
    }
    
    func unlistendAuthEvent() {
        if let _listener = listener {
            Auth.auth().removeStateDidChangeListener(_listener)
        }
    }
    
    func currentUser() -> User? {
        if !FirestoreSetup().isConfigured() {
            return nil
        }
        return Auth.auth().currentUser
    }
    
    func reloadUser() {
        currentUser()?.reload(completion: { (error) in
            if error == nil {
                self.notifyDidUpdateUser()
            }
        })
    }
    
    func isEmailVerified() -> Bool {
        return currentUser()?.isEmailVerified ?? false
    }
    
    func isSignIn() -> Bool {
        return currentUser() != nil
    }
    
    func addObserver(observer: AuthUserNotification) {
        if observers.firstIndex(where: { $0 === observer }) == nil {
            observers.append(observer)
        }
    }
    
    func removeObserver(observer: AuthUserNotification) {
        if let index = observers.firstIndex(where: { $0 === observer }) {
            observers.remove(at: index)
        }
    }
    
    private func notifyDidUpdateUser() {
        observers.forEach { $0.didUpdateUser(authUser: self) }
    }
}
