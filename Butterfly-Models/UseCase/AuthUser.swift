//
//  Auth.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/15.
//

import Foundation
import FirebaseAuth

class AuthUser {
    func currentUser() -> User? {
        if SettingUserDefault.shared.firebasePlistUrl() == nil {
            return nil
        }
        return Auth.auth().currentUser
    }
    
    func reloadUser() {
        currentUser()?.reload()
    }
    
    func isEmailVerified() -> Bool {
        return currentUser()?.isEmailVerified ?? false
    }
}
