//
//  MainViewController.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/10.
//

import Cocoa

class MainViewController: NSViewController, PreferencesWindowControllerDelegate {

    private let window = NSWindow()
    private var preferencesWindowController: PreferencesWindowController?
    
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
    
    func willClose(vc: PreferencesWindowController) {
        preferencesWindowController = nil
    }
    
    @IBAction func pushPreferences(_ sender: Any) {
        let wc = PreferencesWindowController.create()
        wc.delegate = self
        wc.showWindow(window)
        preferencesWindowController = wc
    }

    @IBAction func pushQuit(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
}

