//
//  PreferencesUserViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/13.
//

import Cocoa

class PreferencesUserViewController: NSViewController, NSTextFieldDelegate, SignUpDelegate, SignInOutNotification {
    @IBOutlet weak var signInOutButton: NSButton!
    @IBOutlet weak var signUpButton: NSButton!
    @IBOutlet weak var noteLabel: NSTextField!
    @IBOutlet weak var emailTextField: EditableNSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    
    private let signUp = SignUp()
    private let signInOut = SignInOut.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        signUp.delegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateViewIfFirebaseSettingFinished()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        signInOut.addObserver(observer: self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        signInOut.removeObserver(observer: self)
    }
    
    private func updateViewIfFirebaseSettingFinished() {
        let settingUserDefault = SettingUserDefault.shared
        if settingUserDefault.firebasePlistUrl() != nil {
            emailTextField.isEnabled = true
            passwordTextField.isEnabled = true
            noteLabel.isHidden = true
        } else {
            emailTextField.isEnabled = false
            passwordTextField.isEnabled = false
            noteLabel.isHidden = false
        }
        updateButtonsEnabled()
    }
    
    private func updateButtonsEnabled() {
        if emailTextField.stringValue.isEmpty || passwordTextField.stringValue.isEmpty {
            signInOutButton.isEnabled = false
            signUpButton.isEnabled = false
        } else {
            signInOutButton.isEnabled = true
            signUpButton.isEnabled = true
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateButtonsEnabled()
    }
    
    func didSendEmailVerification(obj: SignUp) {
        AlertBuilder.createCompletionAlert(title: "Email Veriication", message: "An email confirming your email address has been sent.").runModal()
    }
    
    func failedToSignUp(obj: SignUp, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to sign up. \(error.localizedDescription)").runModal()
    }
    
    func didSignIn(obj: SignInOut) {
        print("sign in")
    }
    
    func didSignOut(obj: SignInOut) {
        print("sign out")
    }
    
    @IBAction func pushSignInOut(_ sender: Any) {
        
    }
    
    @IBAction func pushSignUp(_ sender: Any) {
        signUp.send(email: emailTextField.stringValue, password: passwordTextField.stringValue)
    }
}
