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
    
    private let authUser = AuthUser.shared
    private var userData: PreferencesRepository.UserData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        amiVoiceApiUrlTextField.delegate = self
        amiVoiceApiKeyTextField.delegate = self
        updateViews()
        fetchUser()
    }
    
    private func updateViews() {
        amiVoiceSettingsContainer.isHidden = true
        guard let _userData = userData else {
            return
        }
        amiVoiceEnableSwitch.state = _userData.advancedSettingData.enableAmiVoice ? .on : .off
        turnedOnByDefaultSwitch.state = _userData.advancedSettingData.turnedOnByDefault ? .on : .off
        amiVoiceSettingsContainer.isHidden = amiVoiceEnableSwitch.state != .on
        amiVoiceApiUrlTextField.stringValue = _userData.advancedSettingData.amiVoiceApiUrl
        amiVoiceApiKeyTextField.stringValue = _userData.advancedSettingData.amiVoiceApiKey
    }
    
    private func showErrorAlert(error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to access settings. \(error.localizedDescription)").runModal()
    }
    
    private func fetchUser() {
        if let currentUser = authUser.currentUser() {
            async({ _ -> PreferencesRepository.UserData in
                return try await(PreferencesRepository.User().findOrCreate(userId: currentUser.uid))
            }).then({ fetchedUserData in
                self.userData = fetchedUserData
                self.updateViews()
            }).catch { (error) in
                self.showErrorAlert(error: error)
            }
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
            self.updateViews()
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
            self.updateViews()
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
        }
    }
}
