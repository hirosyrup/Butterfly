//
//  SignUp.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/14.
//

import Foundation
import FirebaseAuth

class SignUp: NSObject {
    private var completion: ((Error?) -> Void)?
    
    func send(email: String, password: String, completion comp: @escaping (Error?) -> Void) {
        completion = comp
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let _error = error {
                self.completion?(_error)
                self.completion = nil
            } else if let user = AuthUser().currentUser() {
                user.sendEmailVerification { (error) in
                    if let _error = error {
                        self.completion?(_error)
                    } else {
                        self.completion?(nil)
                    }
                    self.completion = nil
                }
            }
        }
    }
}
