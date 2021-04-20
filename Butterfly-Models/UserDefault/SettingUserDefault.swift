//
//  SettingUserDefault.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/11.
//

import Foundation

class SettingUserDefault {
    static let shared = SettingUserDefault()
    
    let userDefault = UserDefaults.standard
    
    let firebasePlistUrlKey = "firebasePlistUrl"
    
    init() {
        userDefault.register(defaults: [firebasePlistUrlKey: ""])
    }
    
    func saveFirebasePlistUrl(url: URL) {
        userDefault.setValue(url.path, forKey: firebasePlistUrlKey)
    }
    
    func firebasePlistUrl() -> URL? {
        if let str = userDefault.string(forKey: firebasePlistUrlKey) {
            if str.isEmpty {
                return nil
            }
            return URL(fileURLWithPath: str)
        } else {
            return nil
        }
    }
    
    func resetAll() {
        userDefault.removeObject(forKey: firebasePlistUrlKey)
    }
}
