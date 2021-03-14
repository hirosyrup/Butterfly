//
//  SignInOut.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation
import FirebaseAuth

protocol SignInOutNotification: class {
    func didSignIn(obj: SignInOut)
    func didSignOut(obj: SignInOut)
}

class SignInOut {
    static let shared = SignInOut()
    
    private var listener: AuthStateDidChangeListenerHandle?
    
    private var observers = [SignInOutNotification]()
    
    func listenAuthEvent() {
        listener = Auth.auth().addStateDidChangeListener { (auth, user) in
            if auth.currentUser != nil {
                self.notifyDidSignIn()
            } else {
                self.notifyDidSignOut()
            }
        }
    }
    
    func unlistendAuthEvent() {
        if let _listener = listener {
            Auth.auth().removeStateDidChangeListener(_listener)
        }
    }
    
    func addObserver(observer: SignInOutNotification) {
        if observers.firstIndex(where: { $0 === observer }) == nil {
            observers.append(observer)
        }
    }
    
    func removeObserver(observer: SignInOutNotification) {
        if let index = observers.firstIndex(where: { $0 === observer }) {
            observers.remove(at: index)
        }
    }
    
    private func notifyDidSignIn() {
        observers.forEach { $0.didSignIn(obj: self) }
    }
    
    private func notifyDidSignOut() {
        observers.forEach { $0.didSignOut(obj: self) }
    }
}
