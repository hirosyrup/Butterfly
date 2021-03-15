//
//  SignOut.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation
import FirebaseAuth

class SignOut {
    func send() -> Error? {
        do {
            try Auth.auth().signOut()
            return nil
        } catch {
            return error
        }
    }
}
