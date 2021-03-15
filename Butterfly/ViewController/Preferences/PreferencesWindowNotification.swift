//
//  PreferenceWindowNotification.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/15.
//

import Foundation

protocol PreferencesWindowNotificationProtocol: class {
    func windowDidBecomeMain()
}

class PreferencesWindowNotification {
    static let shared = PreferencesWindowNotification()
    
    private var observers = [PreferencesWindowNotificationProtocol]()
    
    func addObserver(observer: PreferencesWindowNotificationProtocol) {
        if observers.firstIndex(where: { $0 === observer }) == nil {
            observers.append(observer)
        }
    }
    
    func removeObserver(observer: PreferencesWindowNotificationProtocol) {
        if let index = observers.firstIndex(where: { $0 === observer }) {
            observers.remove(at: index)
        }
    }
    
    func notifyWindowDidBecomeMain() {
        observers.forEach { $0.windowDidBecomeMain() }
    }
}
