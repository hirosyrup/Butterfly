//
//  StatementSwitchesViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/06/02.
//

import Cocoa

protocol StatementSwitchesViewControllerDelegate: class {
    func didChangeSpeechRecognizerType(vc: StatementSwitchesViewController, recognizerType: SpeechRecognizerType)
}

class StatementSwitchesViewController: NSViewController {
    @IBOutlet weak var speechRecognizerSegmentedControl: NSSegmentedControl!

    weak var delegate: StatementSwitchesViewControllerDelegate?
    
    private var initialRecognizerType: SpeechRecognizerType!
    private var canSelectRecognizer: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizerSegmentedControl.isEnabled = canSelectRecognizer
        speechRecognizerSegmentedControl.selectedSegment = initialRecognizerType.rawValue
    }
    
    func setup(initialRecognizerType: SpeechRecognizerType, canSelectRecognizer: Bool) {
        self.initialRecognizerType = initialRecognizerType
        self.canSelectRecognizer = canSelectRecognizer
    }
    
    @IBAction func changeSpeechRecognizerSetting(_ sender: Any) {
        guard let speechRecognizerType = SpeechRecognizerType(rawValue: speechRecognizerSegmentedControl.selectedSegment) else { return }
        delegate?.didChangeSpeechRecognizerType(vc: self, recognizerType: speechRecognizerType)
    }
}
