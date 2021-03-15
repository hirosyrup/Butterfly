//
//  PreferencesWindowController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/11.
//

import Cocoa

protocol PreferencesWindowControllerDelegate: class {
    func willClose(vc: PreferencesWindowController)
}

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    weak var delegate: PreferencesWindowControllerDelegate?
    
    class func create() -> PreferencesWindowController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PreferencesWindowController")
        return storyboard.instantiateController(withIdentifier: identifier) as! PreferencesWindowController
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.animationBehavior = .documentWindow
        window?.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        delegate?.willClose(vc: self)
    }
}
