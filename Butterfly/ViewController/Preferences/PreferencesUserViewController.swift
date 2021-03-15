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
    @IBOutlet weak var signInIndicator: NSProgressIndicator!
    @IBOutlet weak var signUpIndicator: NSProgressIndicator!
    @IBOutlet weak var fetchUserIndicator: NSProgressIndicator!
    @IBOutlet weak var nameEditContainer: NSStackView!
    @IBOutlet weak var userNameTextField: EditableNSTextField!
    @IBOutlet weak var userNameLabel: NSTextField!
    @IBOutlet weak var editUserNameButton: NSButton!
    
    private let settingUserDefault = SettingUserDefault.shared
    private let authUser = AuthUser.shared
    private var userData: UserData?
    private var isNameEdit = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        fetchUser()
        updateNameEditViews()
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
            nameEditContainer.isHidden = true
            verificationNoteLabel.isHidden = true
            signOutButton.isHidden = true
            signInContainer.isHidden = false
            updateButtonsEnabled()
        } else {
            iconImageButton.isHidden = false
            nameEditContainer.isHidden = false
            signOutButton.isHidden = false
            signInContainer.isHidden = true
            
            if authUser.isEmailVerified() {
                verificationNoteLabel.isHidden = true
            } else {
                verificationNoteLabel.isHidden = false
            }
        }
    }
    
    private func fetchUser() {
        if let currentUser = authUser.currentUser() {
            fetchUserIndicator.startAnimation(self)
            signOutButton.isHidden = true
            UserRepository(userId: currentUser.uid).findOrCreate { (result) in
                self.fetchUserIndicator.stopAnimation(self)
                self.signOutButton.isHidden = false
                switch result {
                case .success(let fetchedUserData):
                    self.userData = fetchedUserData
                    self.updateUserInfoViews()
                case .failure(let error):
                    AlertBuilder.createErrorAlert(title: "Error", message: "Failed to fetch your info. \(error.localizedDescription)").runModal()
                }
            }
        }
    }
    
    private func saveName(currentUserData: UserData, name: String, compltion: @escaping (Result<UserData, Error>) -> Void) {
        var newUserData = currentUserData.copyCurrentAt()
        newUserData.name = name
        UserRepository(userId: currentUserData.id).save(userData: newUserData, compltion: { (result) in
            compltion(result)
        })
    }
    
    private func updateUserInfoViews() {
        if let _userData = userData {
            userNameLabel.stringValue = _userData.name
        }
    }
    
    private func updateNameEditViews() {
        if isNameEdit {
            userNameTextField.isHidden = false
            userNameTextField.stringValue = userData?.name ?? ""
            userNameLabel.isHidden = true
            editUserNameButton.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)
        } else {
            userNameTextField.isHidden = true
            userNameLabel.isHidden = false
            userNameLabel.stringValue = userData?.name ?? ""
            editUserNameButton.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateButtonsEnabled()
    }
    
    func didUpdateUser(authUser: AuthUser) {
        updateContentViews()
        fetchUser()
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
    
    @IBAction func pushEditUserName(_ sender: Any) {
        if isNameEdit {
            if let _userData = userData {
                editUserNameButton.isEnabled = false
                saveName(currentUserData: _userData, name: userNameTextField.stringValue) { (result) in
                    self.editUserNameButton.isEnabled = true
                    switch result {
                    case .success(let savedUserData):
                        self.userData = savedUserData
                        self.isNameEdit = false
                        self.updateNameEditViews()
                    case .failure(let error):
                        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to update your name. \(error.localizedDescription)").runModal()
                    }
                }
            }
        } else {
            isNameEdit = true
            updateNameEditViews()
        }
    }
}
