//
//  PreferencesUserVoiceprintViewController.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/04/28.
//

import Cocoa

class PreferencesUserVoiceprintViewController: NSViewController {
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var levelMeterContainer: NSView!
    weak var levelMeter: StatementLevelMeter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        levelMeter = StatementLevelMeter.createFromNib(owner: nil)
        levelMeter.frame = levelMeterContainer.bounds
        levelMeterContainer.addSubview(levelMeter)
    }
    
    @IBAction func pushStartButton(_ sender: Any) {
    }
}
