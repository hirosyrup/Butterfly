//
//  StatementViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class StatementViewController: NSViewController,
                               SpeechRecognizerDelegate {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var memberIconContainer: MemberIconContainer!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var workspaceId: String!
    private var meetingData: MeetingRepository.MeetingData!
    private let speechRecognizer = SpeechRecognizer.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer.delegate = self
    }

    override func viewDidAppear() {
        speechRecognizer.start()
    }
    
    override func viewWillDisappear() {
        speechRecognizer.stop()
        speechRecognizer.delegate = nil
    }
    
    func setup(workspaceId: String, meetingData: MeetingRepository.MeetingData) {
        self.workspaceId = workspaceId
        self.meetingData = meetingData
        titleLabel.stringValue = meetingData.name
        memberIconContainer.updateView(imageUrls: meetingData.userList.map { $0.iconImageUrl })
    }
    
    func didChangeAvailability(recognizer: SpeechRecognizer) {
        // TODO
    }
    
    func audioEngineStartError(recognizer: SpeechRecognizer, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start audio engine. \(error.localizedDescription)").runModal()
    }
    
    func didNotCreateRecognitionRequest(recognizer: SpeechRecognizer, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "\(error.localizedDescription)").runModal()
    }
    
    func didUpdateStatement(recognizer: SpeechRecognizer, id: String, statement: String) {
    }
    
    func didEndStatement(recognizer: SpeechRecognizer, id: String, statement: String) {
        print("end statement: \(statement)")
    }
}
