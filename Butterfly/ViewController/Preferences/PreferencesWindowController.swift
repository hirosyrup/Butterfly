//
//  PreferencesWindowController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/11.
//

import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    class func create() -> PreferencesWindowController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PreferencesWindowController")
        return storyboard.instantiateController(withIdentifier: identifier) as! PreferencesWindowController
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        window?.delegate = self
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.stopModal(withCode: .cancel)
        window?.orderOut(self)
    }
}
