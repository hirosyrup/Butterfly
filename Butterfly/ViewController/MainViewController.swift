//
//  MainViewController.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/10.
//

import Cocoa

class MainViewController: NSViewController {

    private let preferencesWindowController = PreferencesWindowController.create()
    
    class func create() -> MainViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("MainViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! MainViewController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func pushPreferences(_ sender: Any) {
        if let window = preferencesWindowController.window {
            NSApp.runModal(for: window)
        }
    }

    @IBAction func pushQuit(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
}

