//
//  PreferencesWorkspaceInputViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/17.
//

import Cocoa

class PreferencesWorkspaceInputViewController: NSViewController {
    class func create() -> PreferencesWorkspaceInputViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PreferencesWorkspaceInputViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! PreferencesWorkspaceInputViewController
        return vc
    }
    
    @IBAction func pushCancel(_ sender: Any) {
        dismiss(self)
    }
}
