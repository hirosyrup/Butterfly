//
//  PreferencesUserViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/13.
//

import Cocoa

class PreferencesUserViewController: NSViewController,
                                     NSTextFieldDelegate,
                                     SignUpDelegate,
                                     SignInOutNotification,
                                     PreferencesWindowNotificationProtocol {
    @IBOutlet weak var signInOutButton: NSButton!
    @IBOutlet weak var signUpButton: NSButton!
    @IBOutlet weak var noteLabel: NSTextField!
    @IBOutlet weak var emailTextField: EditableNSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var signInContainer: NSBox!
    @IBOutlet weak var verificationNoteLabel: NSTextField!
    @IBOutlet weak var iconImageButton: NSButton!
    @IBOutlet weak var userNameTextField: NSTextField!
    
    private let settingUserDefault = SettingUserDefault.shared
    private let signUp = SignUp()
    private let signInOut = SignInOut.shared
    private let windowNotification = PreferencesWindowNotification.shared
    
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
        windowNotification.addObserver(observer: self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        signInOut.removeObserver(observer: self)
        windowNotification.removeObserver(observer: self)
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
    
    private func updateButtonsEnabled() {
        if emailTextField.stringValue.isEmpty || passwordTextField.stringValue.isEmpty {
            signInOutButton.isEnabled = false
            signUpButton.isEnabled = false
        } else {
            signInOutButton.isEnabled = true
            signUpButton.isEnabled = true
        }
    }
    
    private func updateContentViews() {
        if settingUserDefault.firebasePlistUrl() == nil || !signInOut.isSignIn() {
            iconImageButton.isHidden = true
            userNameTextField.isHidden = true
            verificationNoteLabel.isHidden = true
            signInContainer.isHidden = false
            updateButtonsEnabled()
        } else {
            iconImageButton.isHidden = false
            userNameTextField.isHidden = false
            signInContainer.isHidden = true
            
            if AuthUser().isEmailVerified() {
                verificationNoteLabel.isHidden = true
            } else {
                verificationNoteLabel.isHidden = false
            }
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
        updateContentViews()
    }
    
    func didSignOut(obj: SignInOut) {
        updateContentViews()
    }
    
    func windowDidBecomeMain() {
        updateContentViews()
    }
    
    @IBAction func pushSignInOut(_ sender: Any) {
        
    }
    
    @IBAction func pushSignUp(_ sender: Any) {
        signUp.send(email: emailTextField.stringValue, password: passwordTextField.stringValue)
    }
}
