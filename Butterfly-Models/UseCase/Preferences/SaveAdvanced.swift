//
//  SaveAdvanced.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/17.
//

import Foundation
import Hydra

class SaveAdvanced {
    let original: PreferencesRepository.UserData
    
    init(data: PreferencesRepository.UserData) {
        self.original = data
    }
    
    func updateEnableAmiVoice(enableAmiVoice: Bool) -> Promise<PreferencesRepository.UserData>{
        var data = original
        data.advancedSettingData.enableAmiVoice = enableAmiVoice
        return update(data: data)
    }
    
    func updateTurnedOnByDefault(turnedOnByDefault: Bool) -> Promise<PreferencesRepository.UserData>{
        var data = original
        data.advancedSettingData.turnedOnByDefault = turnedOnByDefault
        return update(data: data)
    }
    
    func updateAmiVoiceApiUrl(amiVoiceApiUrl: String) -> Promise<PreferencesRepository.UserData>{
        var data = original
        data.advancedSettingData.amiVoiceApiUrl = amiVoiceApiUrl
        return update(data: data)
    }
    
    func updateAmiVoiceApiKey(amiVoiceApiKey: String) -> Promise<PreferencesRepository.UserData>{
        var data = original
        data.advancedSettingData.amiVoiceApiKey = amiVoiceApiKey
        return update(data: data)
    }
    
    func updateAmiVoiceApiEngine(amiVoiceApiEngine: String) -> Promise<PreferencesRepository.UserData>{
        var data = original
        data.advancedSettingData.amiVoiceEngine = amiVoiceApiEngine
        return update(data: data)
    }

    private func update(data: PreferencesRepository.UserData) -> Promise<PreferencesRepository.UserData> {
        return PreferencesRepository.User().update(userData: data)
    }
}
