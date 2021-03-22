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
    private var you: MeetingRepository.MeetingUserData?
    private var statementQueue: StatementQueue!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        if you != nil {
            speechRecognizer.delegate = self
            speechRecognizer.start()
        }
    }
    
    override func viewWillDisappear() {
        if you != nil {
            speechRecognizer.stop()
            speechRecognizer.delegate = nil
        }
    }
    
    func setup(workspaceId: String, meetingData: MeetingRepository.MeetingData) {
        self.workspaceId = workspaceId
        self.meetingData = meetingData
        statementQueue = StatementQueue(workspaceId: workspaceId, meetingId: meetingData.id)
        titleLabel.stringValue = meetingData.name
        memberIconContainer.updateView(imageUrls: meetingData.userList.map { $0.iconImageUrl })
        if let currentUser = AuthUser.shared.currentUser() {
            you = meetingData.userList.first { $0.id == currentUser.uid }
        }
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
    
    func didStartNewStatement(recognizer: SpeechRecognizer, id: String) {
        if let _you = you {
            statementQueue.addNewStatement(statementId: id, user: _you)
        }
    }
    
    func didUpdateStatement(recognizer: SpeechRecognizer, id: String, statement: String) {
        statementQueue.updateStatement(statementId: id, statement: statement)
    }
    
    func didEndStatement(recognizer: SpeechRecognizer, id: String, statement: String) {
        statementQueue.endStatement(statementId: id, statement: statement)
    }
}
