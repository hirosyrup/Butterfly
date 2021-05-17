//
//  PreferencesAdvancedViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/16.
//

import Cocoa
import Hydra

class PreferencesAdvancedViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var amiVoiceEnableSwitch: NSSwitch!
    @IBOutlet weak var amiVoiceSettingsContainer: NSView!
    @IBOutlet weak var turnedOnByDefaultSwitch: NSSwitch!
    @IBOutlet weak var amiVoiceApiUrlTextField: EditableNSTextField!
    @IBOutlet weak var amiVoiceApiKeyTextField: EditableNSTextField!
    @IBOutlet weak var amiVoiceApiEngineTextField: EditableNSTextField!
    @IBOutlet weak var signInNoticeLabel: NSTextField!
    
    private let authUser = AuthUser.shared
    private var userData: PreferencesRepository.UserData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        amiVoiceApiUrlTextField.delegate = self
        amiVoiceApiKeyTextField.delegate = self
        amiVoiceApiEngineTextField.delegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        fetchUser()
        updateViews()
    }
    
    private func updateViews() {
        amiVoiceSettingsContainer.isHidden = true
        signInNoticeLabel.isHidden = true
        guard let _userData = userData else {
            signInNoticeLabel.isHidden = false
            amiVoiceEnableSwitch.isEnabled = false
            return
        }
        amiVoiceEnableSwitch.isEnabled = true
        amiVoiceEnableSwitch.state = _userData.advancedSettingData.enableAmiVoice ? .on : .off
        turnedOnByDefaultSwitch.state = _userData.advancedSettingData.turnedOnByDefault ? .on : .off
        amiVoiceSettingsContainer.isHidden = amiVoiceEnableSwitch.state != .on
        amiVoiceApiUrlTextField.stringValue = _userData.advancedSettingData.amiVoiceApiUrl
        amiVoiceApiKeyTextField.stringValue = _userData.advancedSettingData.amiVoiceApiKey
        amiVoiceApiEngineTextField.stringValue = _userData.advancedSettingData.amiVoiceEngine
    }
    
    private func showErrorAlert(error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to access settings. \(error.localizedDescription)").runModal()
    }
    
    private func fetchUser() {
        if let currentUser = authUser.currentUser(), currentUser.isEmailVerified {
            async({ _ -> PreferencesRepository.UserData in
                return try await(PreferencesRepository.User().findOrCreate(userId: currentUser.uid))
            }).then({ fetchedUserData in
                self.userData = fetchedUserData
                self.updateViews()
            }).catch { (error) in
                self.showErrorAlert(error: error)
            }
        } else {
            userData = nil
        }
    }
    
    private func updateAmiVoiceApiUrl() {
        guard let _userData = userData else {
            return
        }
        let amiVoiceApiUrl = amiVoiceApiUrlTextField.stringValue
        async({ _ -> PreferencesRepository.UserData in
            return try await(SaveAdvanced(data: _userData).updateAmiVoiceApiUrl(amiVoiceApiUrl: amiVoiceApiUrl))
        }).then({ updateData in
            self.userData = updateData
        }).catch { (error) in
            self.showErrorAlert(error: error)
        }
    }
    
    private func updateAmiVoiceApiKey() {
        guard let _userData = userData else {
            return
        }
        let amiVoiceApiKey = amiVoiceApiKeyTextField.stringValue
        async({ _ -> PreferencesRepository.UserData in
            return try await(SaveAdvanced(data: _userData).updateAmiVoiceApiKey(amiVoiceApiKey: amiVoiceApiKey))
        }).then({ updateData in
            self.userData = updateData
        }).catch { (error) in
            self.showErrorAlert(error: error)
        }
    }
    
    private func updateAmiVoiceApiEngine() {
        guard let _userData = userData else {
            return
        }
        let amiVoiceApiEngine = amiVoiceApiEngineTextField.stringValue
        async({ _ -> PreferencesRepository.UserData in
            return try await(SaveAdvanced(data: _userData).updateAmiVoiceApiEngine(amiVoiceApiEngine: amiVoiceApiEngine))
        }).then({ updateData in
            self.userData = updateData
        }).catch { (error) in
            self.showErrorAlert(error: error)
        }
    }
    
    @IBAction func switchEnableAmiVoice(_ sender: Any) {
        guard let _userData = userData else {
            return
        }
        let enableAmiVoice = amiVoiceEnableSwitch.state == .on
        async({ _ -> PreferencesRepository.UserData in
            return try await(SaveAdvanced(data: _userData).updateEnableAmiVoice(enableAmiVoice: enableAmiVoice))
        }).then({ updateData in
            self.userData = updateData
            self.updateViews()
        }).catch { (error) in
            self.showErrorAlert(error: error)
        }
    }
    
    @IBAction func switchTurnedOnByDefault(_ sender: Any) {
        guard let _userData = userData else {
            return
        }
        let turnedOnByDefault = turnedOnByDefaultSwitch.state == .on
        async({ _ -> PreferencesRepository.UserData in
            return try await(SaveAdvanced(data: _userData).updateTurnedOnByDefault(turnedOnByDefault: turnedOnByDefault))
        }).then({ updateData in
            self.userData = updateData
            self.updateViews()
        }).catch { (error) in
            self.showErrorAlert(error: error)
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if (obj.object as? EditableNSTextField) === amiVoiceApiUrlTextField {
            updateAmiVoiceApiUrl()
        } else if (obj.object as? EditableNSTextField) === amiVoiceApiKeyTextField {
            updateAmiVoiceApiKey()
        } else if (obj.object as? EditableNSTextField) === amiVoiceApiEngineTextField {
            updateAmiVoiceApiEngine()
        }
    }
}
