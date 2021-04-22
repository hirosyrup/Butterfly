//
//  AboutViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/22.
//

import Cocoa

class AboutViewController: NSViewController {
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var copyLightLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionLabel.stringValue = "version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)"
        copyLightLabel.stringValue = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as! String
    }
}
