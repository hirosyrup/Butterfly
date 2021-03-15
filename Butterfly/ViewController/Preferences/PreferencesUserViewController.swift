//
//  PreferencesUserViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/13.
//

import Cocoa

class PreferencesUserViewController: NSViewController,
                                     NSTextFieldDelegate,
                                     AuthUserNotification {
    @IBOutlet weak var signInButton: NSButton!
    @IBOutlet weak var signUpButton: NSButton!
    @IBOutlet weak var signOutButton: NSButton!
    @IBOutlet weak var noteLabel: NSTextField!
    @IBOutlet weak var emailTextField: EditableNSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var signInContainer: NSBox!
    @IBOutlet weak var verificationNoteLabel: NSTextField!
    @IBOutlet weak var iconImageButton: NSButton!
    @IBOutlet weak var userNameTextField: NSTextField!
    @IBOutlet weak var signInIndicator: NSProgressIndicator!
    @IBOutlet weak var signUpIndicator: NSProgressIndicator!
    
    private let settingUserDefault = SettingUserDefault.shared
    private let authUser = AuthUser.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateViewIfFirebaseSettingFinished()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        authUser.addObserver(observer: self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        authUser.removeObserver(observer: self)
    }
    
    private func updateViewIfFirebaseSettingFinished() {
        if settingUserDefault.firebasePlistUrl() != nil {
            emailTextField.isEnabled = true
            passwordTextField.isEnabled = true
            noteLabel.isHidden = true
        } else {
            emailTextField.isEnabled = false
            passwordTextField.isEnabled = false
            noteLabel.isHidden = false
        }
        
        updateContentViews()
    }
    
    private func updateButtonsEnabled(isEnabled: Bool? = nil) {
        if let _isEnabled = isEnabled {
            signInButton.isEnabled = _isEnabled
            signUpButton.isEnabled = _isEnabled
            return
        }
        
        if emailTextField.stringValue.isEmpty || passwordTextField.stringValue.isEmpty{
            signInButton.isEnabled = false
            signUpButton.isEnabled = false
        } else {
            signInButton.isEnabled = true
            signUpButton.isEnabled = true
        }
    }
    
    private func updateContentViews() {
        if settingUserDefault.firebasePlistUrl() == nil || !authUser.isSignIn() {
            iconImageButton.isHidden = true
            userNameTextField.isHidden = true
            verificationNoteLabel.isHidden = true
            signOutButton.isHidden = true
            signInContainer.isHidden = false
            updateButtonsEnabled()
        } else {
            iconImageButton.isHidden = false
            userNameTextField.isHidden = false
            signOutButton.isHidden = false
            signInContainer.isHidden = true
            
            if authUser.isEmailVerified() {
                verificationNoteLabel.isHidden = true
            } else {
                verificationNoteLabel.isHidden = false
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateButtonsEnabled()
    }
    
    func didUpdateUser(authUser: AuthUser) {
        updateContentViews()
    }
    
    func windowDidBecomeMain() {
        updateContentViews()
    }
    
    @IBAction func pushSignIn(_ sender: Any) {
        signInIndicator.startAnimation(self)
        updateButtonsEnabled(isEnabled: false)
        SignIn().send(email: emailTextField.stringValue, password: passwordTextField.stringValue) { (error) in
            self.signInIndicator.stopAnimation(self)
            self.updateButtonsEnabled(isEnabled: true)
            if let _error = error {
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to sign in. \(_error.localizedDescription)").runModal()
            } else {
                self.updateContentViews()
            }
        }
    }
    
    @IBAction func pushSignOut(_ sender: Any) {
        if let error = SignOut().send() {
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to sign out. \(error.localizedDescription)").runModal()
        }
    }
    
    @IBAction func pushSignUp(_ sender: Any) {
        signUpIndicator.startAnimation(self)
        updateButtonsEnabled(isEnabled: false)
        SignUp().send(email: emailTextField.stringValue, password: passwordTextField.stringValue) { (error) in
            self.signUpIndicator.stopAnimation(self)
            self.updateButtonsEnabled(isEnabled: true)
            if let _error = error {
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to sign up. \(_error.localizedDescription)").runModal()
            } else {
                AlertBuilder.createCompletionAlert(title: "Email Veriication", message: "An email confirming your email address has been sent.").runModal()
            }
        }
    }
}
