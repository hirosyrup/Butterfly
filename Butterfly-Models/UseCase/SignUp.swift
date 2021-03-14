//
//  SignUp.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/14.
//

import Foundation
import FirebaseAuth

protocol SignUpDelegate: class {
    func didSendEmailVerification(obj: SignUp)
    func failedToSignUp(obj: SignUp, error: Error)
}

class SignUp: NSObject {
    weak var delegate: SignUpDelegate?
    
    func send(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let _error = error {
                self.delegate?.failedToSignUp(obj: self, error: _error)
            } else if let user = Auth.auth().currentUser {
                user.sendEmailVerification { (error) in
                    if let _error = error {
                        self.delegate?.failedToSignUp(obj: self, error: _error)
                    } else {
                        self.delegate?.didSendEmailVerification(obj: self)
                    }
                }
            }
        }
    }
}
