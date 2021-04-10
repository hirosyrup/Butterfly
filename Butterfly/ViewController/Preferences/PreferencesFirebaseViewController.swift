//
//  PreferencesFirebaseViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/11.
//

import Cocoa

class PreferencesFirebaseViewController: NSViewController {
    @IBOutlet weak var plistNameLabel: NSTextField!
    
    let settingUserDefault = SettingUserDefault.shared
    
    override func viewDidLoad() {
        if let plistUrl = settingUserDefault.firebasePlistUrl() {
            plistNameLabel.stringValue = plistUrl.lastPathComponent
        }
    }
    
    @IBAction func pushImportButton(_ sender: Any) {
        guard let window = NSApp.keyWindow else { return }
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select plist of connection settings for Fireabase."
        openPanel.allowedFileTypes = ["plist"]
        openPanel.beginSheetModal(for: window, completionHandler: { (response) in
            if response == .OK {
                if let url = openPanel.url {
                    let fileManager = FileManager.default
                    let localUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
                    let toUrl = localUrl.appendingPathComponent(url.lastPathComponent)
                    if fileManager.fileExists(atPath: toUrl.path) {
                        try! fileManager.removeItem(at: toUrl)
                    }
                    try! fileManager.copyItem(at: url, to: toUrl)
                    let fileName = url.lastPathComponent
                    self.plistNameLabel.stringValue = fileName
                    self.settingUserDefault.saveFirebasePlistUrl(url: toUrl)
                    FirestoreSetup().setup { (neetUpdate) in
                        if neetUpdate {
                            let alert = AlertBuilder.createNeedUpdateAlert()
                            if alert.runModal() == .alertFirstButtonReturn {
                                NSApplication.shared.terminate(self)
                            }
                        }
                    }
                }
            }
        })
    }
}
