//
//  MainViewController.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/10.
//

import Cocoa
import Hydra
import WebKit

class MainViewController: NSViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    class func create() -> MainViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("MainViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! MainViewController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: URL(string: "https://spatial.chat/s/KiizanKiizanDev")!))
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
}

