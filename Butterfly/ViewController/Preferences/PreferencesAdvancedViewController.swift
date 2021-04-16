//
//  PreferencesAdvancedViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/16.
//

import Cocoa

class PreferencesAdvancedViewController: NSViewController {
    @IBOutlet weak var amiVoiceEnableSwitch: NSSwitch!
    @IBOutlet weak var amiVoiceSettingsContainer: NSView!
    @IBOutlet weak var turnedOnByDefaultSwitch: NSTextField!
    @IBOutlet weak var amiVoiceApiUrlTextField: EditableNSTextField!
    @IBOutlet weak var amiVoiceApiKeyTextFild: EditableNSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViews()
    }
    
    private func updateViews() {
        amiVoiceSettingsContainer.isHidden = amiVoiceEnableSwitch.state != .on
    }
    
    @IBAction func switchEnableAmiVoice(_ sender: Any) {
        updateViews()
    }
}
