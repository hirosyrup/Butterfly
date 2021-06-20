//
//  StatementSwitchesViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/06/02.
//

import Cocoa

protocol StatementSwitchesViewControllerDelegate: class {
    func didChangeSpeechRecognizerType(vc: StatementSwitchesViewController, recognizerType: SpeechRecognizerType)
    func didChangeIsMutingSilentPart(vc: StatementSwitchesViewController, isMutingSilentPart: Bool)
    func didChangeIsAutoScroll(vc: StatementSwitchesViewController, isAutoScroll: Bool)
}

class StatementSwitchesViewController: NSViewController {
    @IBOutlet weak var speechRecognizerSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var isMutingSilentPartSwitch: NSSwitch!
    @IBOutlet weak var isAutoScrollSwitch: NSSwitch!

    weak var delegate: StatementSwitchesViewControllerDelegate?
    
    private var initialRecognizerType: SpeechRecognizerType!
    private var canSelectRecognizer: Bool!
    private var initialIsMutingSilentPart: Bool!
    private var initialIsAutoScroll: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizerSegmentedControl.isEnabled = canSelectRecognizer
        speechRecognizerSegmentedControl.selectedSegment = initialRecognizerType.rawValue
        isMutingSilentPartSwitch.state = initialIsMutingSilentPart ? .on : .off
        isAutoScrollSwitch.state = initialIsAutoScroll ? .on : .off
    }
    
    func setup(initialRecognizerType: SpeechRecognizerType, canSelectRecognizer: Bool, isMutingSilentPart: Bool, isAutoScroll: Bool) {
        self.initialRecognizerType = initialRecognizerType
        self.canSelectRecognizer = canSelectRecognizer
        self.initialIsMutingSilentPart = isMutingSilentPart
        self.initialIsAutoScroll = isAutoScroll
    }
    
    @IBAction func changeSpeechRecognizerSetting(_ sender: Any) {
        guard let speechRecognizerType = SpeechRecognizerType(rawValue: speechRecognizerSegmentedControl.selectedSegment) else { return }
        delegate?.didChangeSpeechRecognizerType(vc: self, recognizerType: speechRecognizerType)
    }
    
    @IBAction func switchIsMutingSilentPart(_ sender: Any) {
        if let _switch = sender as? NSSwitch {
            delegate?.didChangeIsMutingSilentPart(vc: self, isMutingSilentPart: _switch.state == .on)
        }
    }
    
    @IBAction func switchIsAutoScroll(_ sender: Any) {
        if let _switch = sender as? NSSwitch {
            delegate?.didChangeIsAutoScroll(vc: self, isAutoScroll: _switch.state == .on)
        }
    }
}
