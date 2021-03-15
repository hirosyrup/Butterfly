//
//  SignInOut.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation
import FirebaseAuth

class SignIn {
    private var completion: ((Error?) -> Void)?
    
    func send(email: String, password: String, completion comp: @escaping (Error?) -> Void) {
        self.completion = comp
        Auth.auth().signIn(withEmail: email, password: password) { (_, error) in
            self.completion?(error)
            self.completion = nil
        }
    }
}
