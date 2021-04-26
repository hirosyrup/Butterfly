//
//  PreferencesUserViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/13.
//

import Cocoa
import Hydra
import Speech

class PreferencesUserViewController: NSViewController,
                                     NSTextFieldDelegate,
                                     AuthUserNotification {
    enum RequestState {
        case none
        case isFetchingUser
        case isPocessingSignIn
        case isPocessingSignUp
        case isProcessingSaveName
        case isProcessingSaveIcon
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
    @IBOutlet weak var languageContainer: NSStackView!
    @IBOutlet weak var languagePopupButton: NSPopUpButton!
    @IBOutlet weak var iconImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var voicePrintContainer: NSStackView!
    @IBOutlet weak var voicePrintCheckMark: NSImageView!
    @IBOutlet weak var createVoicePrintButton: NSButton!
    
    private let settingUserDefault = SettingUserDefault.shared
    private let authUser = AuthUser.shared
    private var userData: PreferencesRepository.UserData?
    private var isNameEdit = false
    private var requestState = RequestState.none
    private var languageOptions = [PopupButtonOption]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        setupIconImageButton()
        setupLanguagePopupButton()
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
    
    private func setupIconImageButton() {
        iconImageButton.wantsLayer = true
        iconImageButton.layer?.cornerRadius = iconImageHeightConstraint.constant / 2.0
    }
    
    private func setupLanguagePopupButton() {
        languageOptions = SFSpeechRecognizer.supportedLocales().map { PopupButtonOption(id: $0.identifier, value: $0.localizedString(forIdentifier: $0.identifier) ?? "") }
        languageOptions = languageOptions.sorted(by: { $0.value < $1.value })
        languagePopupButton.addItem(withTitle: "")
        languagePopupButton.addItems(withTitles: languageOptions.map { $0.value })
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
        languageContainer.isHidden = false
        fetchUserIndicator.isHidden = true
        voicePrintContainer.isHidden = true
        
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
            fetchUserIndicator.isHidden = false
            fetchUserIndicator.startAnimation(self)
            signInButton.isHidden = true
            signUpButton.isHidden = true
            emailTextField.isHidden = true
            passwordTextField.isHidden = true
            signInContainer.isHidden = true
            signOutButton.isHidden = true
            noteLabel.isHidden = true
            verificationNoteLabel.isHidden = true
            iconImageButton.isHidden = true
            nameEditContainer.isHidden = true
            userNameTextField.isHidden = true
            userNameLabel.isHidden = true
            editUserNameButton.isHidden = true
            languageContainer.isHidden = true
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
            languageContainer.isHidden = true
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
            languageContainer.isHidden = true
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
            userNameLabel.isHidden = true
            signOutButton.isEnabled = false
            iconImageButton.isEnabled = false
            editUserNameButton.isEnabled = false
        case .isProcessingSaveIcon:
            signInButton.isHidden = true
            signUpButton.isHidden = true
            noteLabel.isHidden = true
            emailTextField.isHidden = true
            passwordTextField.isHidden = true
            signInContainer.isHidden = true
            verificationNoteLabel.isHidden = true
            userNameTextField.isHidden = true
            signOutButton.isEnabled = false
            iconImageButton.isEnabled = false
            editUserNameButton.isEnabled = false
        case .none:
            fetchUserIndicator.stopAnimation(self)
            signInIndicator.stopAnimation(self)
            signUpIndicator.stopAnimation(self)
            if !FirestoreSetup().isConfigured() {
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
                languageContainer.isHidden = true
            } else if authUser.isSignIn() {
                if authUser.isEmailVerified() {
                    signInButton.isHidden = true
                    signUpButton.isHidden = true
                    noteLabel.isHidden = true
                    verificationNoteLabel.isHidden = true
                    emailTextField.isHidden = true
                    passwordTextField.isHidden = true
                    signInContainer.isHidden = true
                    voicePrintContainer.isHidden = false
                    if isNameEdit {
                        userNameLabel.isHidden = true
                        editUserNameButton.image = NSImage(named: "checkmark")
                    } else {
                        userNameTextField.isHidden = true
                        userNameLabel.stringValue = userData?.name ?? ""
                        editUserNameButton.image = NSImage(named: "pencil")
                    }
                    if let index = languageOptions.firstIndex(where: {$0.id == userData?.language}) {
                        let itemIndex = index + 1
                        languagePopupButton.selectItem(at: itemIndex)
                        languagePopupButton.setTitle(languageOptions[index].value)
                    }
                    if userData?.voicePrintName != nil {
                        createVoicePrintButton.stringValue = "Upldate voiceprint"
                        voicePrintCheckMark.isHidden = false
                    } else {
                        createVoicePrintButton.stringValue = "Create voiceprint"
                        voicePrintCheckMark.isHidden = true
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
                    languageContainer.isHidden = true
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
                languageContainer.isHidden = true
                
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
            async({ _ -> PreferencesRepository.UserData in
                return try await(PreferencesRepository.User().findOrCreate(userId: currentUser.uid))
            }).then({ fetchedUserData in
                self.userData = fetchedUserData
                self.updateUserInfoViews()
            }).catch { (error) in
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to fetch your info. \(error.localizedDescription)").runModal()
            }.always(in: .main) {
                self.requestState = RequestState.none
                self.updateViews()
            }
        }
    }
    
    private func saveName(currentUserData: PreferencesRepository.UserData, name: String) -> Promise<PreferencesRepository.UserData> {
        return Promise<PreferencesRepository.UserData>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> PreferencesRepository.UserData in
                var newUserData = currentUserData
                newUserData.name = name
                return try await(PreferencesRepository.User().update(userData: newUserData))
            }).then({ userData in
                resolve(userData)
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func saveIconName(currentUserData: PreferencesRepository.UserData, iconName: String) -> Promise<PreferencesRepository.UserData> {
        return Promise<PreferencesRepository.UserData>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> PreferencesRepository.UserData in
                var newUserData = currentUserData
                newUserData.iconName = iconName
                return try await(PreferencesRepository.User().update(userData: newUserData))
            }).then({ userData in
                resolve(userData)
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    private func updateUserInfoViews() {
        if let _userData = userData {
            userNameLabel.stringValue = _userData.name
            if let iconName = _userData.iconName {
                IconImage.shared.fetchDownloadUrl(fileName: iconName)
                    .then(in: .main, { downloadUrl in
                        self.setIconImage(url: downloadUrl)
                    })
                    .catch { (error) in
                        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to download the icon image. \(error.localizedDescription)").runModal()
                    }
            }
        }
    }
    
    private func uploadIcon(url: URL) {
        guard let _userData = userData else { return }
        requestState = RequestState.isProcessingSaveIcon
        updateViews()
        UploadIconImage(uploadImageUrl: url, fileName: _userData.iconName).execute { (result) in
            switch result {
            case .success(let response):
                self.setIconImage(url: response.downloadUrl)
                async({ _ -> PreferencesRepository.UserData in
                    return try await(self.saveIconName(currentUserData: _userData, iconName: response.savedName))
                }).then({ response in
                    self.userData?.iconName = response.iconName
                }).catch { (error) in
                    AlertBuilder.createErrorAlert(title: "Error", message: "Failed to save the icon name. \(error.localizedDescription)").runModal()
                }.always(in: .main) {
                    self.requestState = RequestState.none
                    self.updateViews()
                }
            case .failure(let error):
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to upload the icon image. \(error.localizedDescription)").runModal()
            }
        }
    }
    
    private func setIconImage(url: URL?) {
        guard url != nil else { return }
        DispatchQueue.global().async {
            let imageData: Data? = try? Data(contentsOf: url!)
            DispatchQueue.main.async {
                if let data = imageData, let loadedImage = NSImage(data: data) {
                    self.iconImageButton.image = loadedImage
                    self.iconImageButton.layoutSubtreeIfNeeded()
                }
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateViews()
    }
    
    func didUpdateUser(authUser: AuthUser) {
        let firestoreObserver = FirestoreObserver.shared
        if authUser.isSignIn() {
            firestoreObserver.listenWorkspace()
        } else {
            firestoreObserver.unlistenWorkspace()
        }
        fetchUser()
    }
    
    @IBAction func pushSignIn(_ sender: Any) {
        requestState = RequestState.isPocessingSignIn
        updateViews()
        SignIn().send(email: emailTextField.stringValue, password: passwordTextField.stringValue) { (error) in
            if let _error = error {
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to sign in. \(_error.localizedDescription)").runModal()
            } else {
                self.fetchUser()
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
                let newName = self.userNameTextField.stringValue
                async({ _ -> PreferencesRepository.UserData in
                    return try await(self.saveName(currentUserData: _userData, name: newName))
                }).then({ savedUserData in
                    self.userData = savedUserData
                    self.isNameEdit = false
                    self.updateViews()
                }).catch { (error) in
                    AlertBuilder.createErrorAlert(title: "Error", message: "Failed to update your name. \(error.localizedDescription)").runModal()
                }.always(in: .main) {
                    self.requestState = RequestState.none
                    self.updateViews()
                }
            }
        } else {
            isNameEdit = true
            userNameTextField.stringValue = userData?.name ?? ""
            updateViews()
        }
    }
    
    @IBAction func pushIconImageButton(_ sender: Any) {
        guard let window = NSApp.keyWindow else { return }
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Choose an image for the icon."
        openPanel.allowedFileTypes = ["jpg", "jpeg", "png"]
        openPanel.beginSheetModal(for: window, completionHandler: { (response) in
            if response == .OK {
                if let url = openPanel.url {
                    self.uploadIcon(url: url)
                }
            }
        })
    }
    
    @IBAction func didChangeLanguagePopup(_ sender: Any) {
        let index = languagePopupButton.indexOfSelectedItem - 1
        if var _userData = userData, languageOptions.count > index {
            _userData.language = languageOptions[index].id
            async({ _ -> PreferencesRepository.UserData in
                return try await(PreferencesRepository.User().update(userData: _userData))
            }).then({ savedUserData in
                self.userData = savedUserData
                self.updateViews()
            }).catch { (error) in
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to update the language. \(error.localizedDescription)").runModal()
            }
        }
    }
}
