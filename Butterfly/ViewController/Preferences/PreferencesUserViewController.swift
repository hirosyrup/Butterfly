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
    enum RequestState {
        case none
        case isFetchingUser
        case isPocessingSignIn
        case isPocessingSignUp
        case isProcessingSaveName
    }
    
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
    private var requestState = RequestState.none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        fetchUser()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateViews()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        authUser.addObserver(observer: self)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        authUser.removeObserver(observer: self)
    }
    
    private func updateViews() {
        signInButton.isHidden = false
        signUpButton.isHidden = false
        signOutButton.isHidden = false
        noteLabel.isHidden = false
        emailTextField.isHidden = false
        passwordTextField.isHidden = false
        signInContainer.isHidden = false
        verificationNoteLabel.isHidden = false
        iconImageButton.isHidden = false
        nameEditContainer.isHidden = false
        userNameTextField.isHidden = false
        userNameLabel.isHidden = false
        editUserNameButton.isHidden = false
        
        signInButton.isEnabled = true
        signUpButton.isEnabled = true
        signOutButton.isEnabled = true
        noteLabel.isEnabled = true
        emailTextField.isEnabled = true
        passwordTextField.isEnabled = true
        verificationNoteLabel.isEnabled = true
        iconImageButton.isEnabled = true
        userNameTextField.isEnabled = true
        userNameLabel.isEnabled = true
        editUserNameButton.isEnabled = true
        
        switch requestState {
        case .isFetchingUser:
            fetchUserIndicator.startAnimation(self)
        case .isPocessingSignIn:
            signInIndicator.startAnimation(self)
            signOutButton.isHidden = true
            noteLabel.isHidden = true
            verificationNoteLabel.isHidden = true
            iconImageButton.isHidden = true
            nameEditContainer.isHidden = true
            userNameTextField.isHidden = true
            userNameLabel.isHidden = true
            editUserNameButton.isHidden = true
            emailTextField.isEnabled = false
            passwordTextField.isEnabled = false
            signInButton.isEnabled = false
            signUpButton.isEnabled = false
        case .isPocessingSignUp:
            signUpIndicator.startAnimation(self)
            signOutButton.isHidden = true
            noteLabel.isHidden = true
            verificationNoteLabel.isHidden = true
            iconImageButton.isHidden = true
            nameEditContainer.isHidden = true
            userNameTextField.isHidden = true
            userNameLabel.isHidden = true
            editUserNameButton.isHidden = true
            emailTextField.isEnabled = false
            passwordTextField.isEnabled = false
            signInButton.isEnabled = false
            signUpButton.isEnabled = false
        case .isProcessingSaveName:
            signInButton.isHidden = true
            signUpButton.isHidden = true
            noteLabel.isHidden = true
            emailTextField.isHidden = true
            passwordTextField.isHidden = true
            signInContainer.isHidden = true
            verificationNoteLabel.isHidden = true
            signOutButton.isEnabled = false
            iconImageButton.isEnabled = false
            userNameTextField.isEnabled = false
            editUserNameButton.isEnabled = false
        case .none:
            fetchUserIndicator.stopAnimation(self)
            signInIndicator.stopAnimation(self)
            signUpIndicator.stopAnimation(self)
            if settingUserDefault.firebasePlistUrl() == nil {
                signInButton.isHidden = true
                signUpButton.isHidden = true
                signOutButton.isHidden = true
                emailTextField.isHidden = true
                passwordTextField.isHidden = true
                verificationNoteLabel.isHidden = true
                iconImageButton.isHidden = true
                nameEditContainer.isHidden = true
                userNameTextField.isHidden = true
                userNameLabel.isHidden = true
                editUserNameButton.isHidden = true
            } else if authUser.isSignIn() {
                if authUser.isEmailVerified() {
                    signInButton.isHidden = true
                    signUpButton.isHidden = true
                    noteLabel.isHidden = true
                    verificationNoteLabel.isHidden = true
                    emailTextField.isHidden = true
                    passwordTextField.isHidden = true
                    signInContainer.isHidden = true
                    userNameTextField.isHidden = true
                    userNameLabel.isHidden = true
                    if isNameEdit {
                        userNameLabel.isHidden = true
                        userNameTextField.stringValue = userData?.name ?? ""
                        editUserNameButton.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil)
                    } else {
                        userNameTextField.isHidden = false
                        userNameLabel.stringValue = userData?.name ?? ""
                        editUserNameButton.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
                    }
                } else {
                    signInButton.isHidden = true
                    signUpButton.isHidden = true
                    signOutButton.isHidden = true
                    noteLabel.isHidden = true
                    emailTextField.isHidden = true
                    passwordTextField.isHidden = true
                    signInContainer.isHidden = true
                    iconImageButton.isHidden = true
                    nameEditContainer.isHidden = true
                    userNameTextField.isHidden = true
                    userNameLabel.isHidden = true
                    editUserNameButton.isHidden = true
                }
            } else {
                signOutButton.isHidden = true
                noteLabel.isHidden = true
                verificationNoteLabel.isHidden = true
                iconImageButton.isHidden = true
                nameEditContainer.isHidden = true
                userNameTextField.isHidden = true
                userNameLabel.isHidden = true
                editUserNameButton.isHidden = true
                
                if emailTextField.stringValue.isEmpty || passwordTextField.stringValue.isEmpty{
                    signInButton.isEnabled = false
                    signUpButton.isEnabled = false
                }
            }
        }
    }
    
    private func fetchUser() {
        if let currentUser = authUser.currentUser() {
            requestState = RequestState.isFetchingUser
            updateViews()
            UserRepository(userId: currentUser.uid).findOrCreate { (result) in
                self.requestState = RequestState.none
                self.updateViews()
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
    
    func controlTextDidChange(_ obj: Notification) {
        updateViews()
    }
    
    func didUpdateUser(authUser: AuthUser) {
        fetchUser()
    }
    
    @IBAction func pushSignIn(_ sender: Any) {
        requestState = RequestState.isPocessingSignIn
        updateViews()
        SignIn().send(email: emailTextField.stringValue, password: passwordTextField.stringValue) { (error) in
            self.requestState = RequestState.none
            self.updateViews()
            if let _error = error {
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to sign in. \(_error.localizedDescription)").runModal()
            }
        }
    }
    
    @IBAction func pushSignOut(_ sender: Any) {
        if let error = SignOut().send() {
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to sign out. \(error.localizedDescription)").runModal()
        } else {
            updateViews()
        }
    }
    
    @IBAction func pushSignUp(_ sender: Any) {
        requestState = RequestState.isPocessingSignUp
        updateViews()
        SignUp().send(email: emailTextField.stringValue, password: passwordTextField.stringValue) { (error) in
            self.requestState = RequestState.none
            self.updateViews()
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
                requestState = RequestState.isProcessingSaveName
                updateViews()
                saveName(currentUserData: _userData, name: userNameTextField.stringValue) { (result) in
                    self.requestState = RequestState.none
                    self.updateViews()
                    switch result {
                    case .success(let savedUserData):
                        self.userData = savedUserData
                        self.isNameEdit = false
                        self.updateViews()
                    case .failure(let error):
                        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to update your name. \(error.localizedDescription)").runModal()
                    }
                }
            }
        } else {
            isNameEdit = true
            updateViews()
        }
    }
}
