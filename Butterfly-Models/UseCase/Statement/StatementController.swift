//
//  StatementController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/06.
//

import Foundation
import AVFoundation
import Hydra

protocol StatementControllerDelegate: class {
    func didNotCreateRecognitionRequest(controller: StatementController, error: Error)
    func audioEngineStartError(controller: StatementController, error: Error)
    func didUpdateData(controller: StatementController)
}

class StatementController: SpeechRecognizerDelegate,
                           AudioSystemDelegate,
                           SpeakerRecognizerDelegate,
                           MeetingRepositoryDataDelegate,
                           MeetingUserRepositoryDataListDelegate {
    private(set) var meetingData: MeetingRepository.MeetingData
    private(set) var userList = [MeetingUserRepository.MeetingUserData]()
    private(set) var you: MeetingUserRepository.MeetingUserData?
    
    weak var delegate: StatementControllerDelegate?
    
    private let workspaceId: String
    private let speakerRecognizer: SpeakerRecognizer?
    private let speechRecognizer: SpeechRecognizer?
    private let audioSystem = AudioSystem.shared
    private let audioRecorder: AudioRecorder?
    private var isAudioInputStart = false
    private let observeBreakInStatements = ObserveBreakInStatements(limitTime: nil)
    private let autoCalcRmsThreshold: AutoCalcRmsThreshold
    private var audioComposition: AVMutableComposition?
    private var currentSpeaker: MeetingUserRepository.MeetingUserData?
    private var statementQueue: StatementQueue!
    private let meetingUser = MeetingUserRepository.User()
    private let meeting = MeetingRepository.Meeting()
    
    init(workspaceId: String, workspaceMLFileName: String?, initialMeetingData: MeetingRepository.MeetingData) {
        self.autoCalcRmsThreshold = AutoCalcRmsThreshold(initialThreshold: observeBreakInStatements.rmsThreshold)
        self.workspaceId = workspaceId
        if let _workspaceMLFileName = workspaceMLFileName {
            let compiledFileName = MLFileLocalUrl.createCompiledModelFileName(modelFileName: _workspaceMLFileName)
            let compileModelFileUrl = MLFileLocalUrl.createLocalUrl().appendingPathComponent(compiledFileName)
            if FileManager.default.fileExists(atPath: compileModelFileUrl.path) {
                self.speakerRecognizer = SpeakerRecognizer(compileModelFileUrl: compileModelFileUrl, format: audioSystem.inputFormat)
                self.speakerRecognizer?.delegate = self
            }
        }
        self.meetingData = initialMeetingData
        statementQueue = StatementQueue(workspaceId: workspaceId, meetingId: initialMeetingData.id)
    }
    
    private func enter() {
        guard var _you = you else { return }
        if !_you.isEntering {
            async({ _ -> MeetingUserRepository.MeetingUserData in
                _you.isEntering = true
                return try await(MeetingUserRepository.User().update(workspaceId: self.workspaceId, meetingId: self.meetingData.id, meetingUserData: _you))
            }).then { (_) in }
        }
    }
    
    private func exit() {
        guard var _you = you else { return }
        if _you.isEntering {
            async({ _ -> MeetingUserRepository.MeetingUserData in
                _you.isEntering = false
                return try await(MeetingUserRepository.User().update(workspaceId: self.workspaceId, meetingId: self.meetingData.id, meetingUserData: _you))
            }).then { (_) in }
        }
    }
    
    private func updateYou() {
        if let currentUser = AuthUser.shared.currentUser() {
            if let _you = userList.first(where: { $0.userId == currentUser.uid }) {
                if _you.id != you?.id {
                    setupSpeechRecognizer(you: _you)
                }
                if speakerRecognizer == nil {
                    currentSpeaker = _you
                }
                you = _you
            }
        }
    }
    
    func listenData() {
        meetingUser.listen(workspaceId: workspaceId, meetingId: meetingData.id, dataListDelegate: self)
        meeting.listen(workspaceId: workspaceId, meetingId: meetingData.id, dataDelegate: self)
    }
    
    func unlistenData() {
        meetingUser.unlisten()
        meeting.unlisten()
    }
    
    func startRecognition() throws {
        audioSystem.delegate = self
        audioSystem.start()
        try speakerRecognizer?.start()
    }
    
    func stopRecognition() {
        audioSystem.stop()
        speechRecognizer?.setDelegate(delegate: nil)
        audioSystem.delegate = nil
        speakerRecognizer?.stop()
    }
    
    func createStatementShareViewControllerData(statementDataList: [StatementRepository.StatementData]) -> StatementShareViewControllerData {
        return StatementShareViewControllerData(
            workspaceId: workspaceId,
            meetingData: meetingData,
            statementDataList: statementDataList,
            audioComposition: audioComposition
        )
    }
    
    func didChangeAvailability(recognizer: SpeechRecognizer) {
        // TODO
    }
    
    func didNotCreateRecognitionRequest(recognizer: SpeechRecognizer, error: Error) {
        delegate?.didNotCreateRecognitionRequest(controller: self, error: error)
    }
    
    func didStartNewStatement(recognizer: SpeechRecognizer, id: String) {
        statementQueue.addNewStatement(uuid: id, user: currentSpeaker)
    }
    
    func didUpdateStatement(recognizer: SpeechRecognizer, id: String, statement: String) {
        statementQueue.updateStatement(uuid: id, statement: statement, user: currentSpeaker)
    }
    
    func didEndStatement(recognizer: SpeechRecognizer, id: String, statement: String) {
        statementQueue.endStatement(uuid: id, statement: statement, user: currentSpeaker)
    }
    
    func didChangeMeetingUserDataList(obj: MeetingUserRepository.User, documentChanges: [RepositoryDocumentChange<MeetingUserRepository.MeetingUserData>]) {
        userList = meetingUser.createUserListFromDocumentChanges(prevUserList: userList, documentChanges: documentChanges)
        updateYou()
        updateViews()
        enter()
        setupRecordAudioIfNeeded()
        delegate?.didUpdateData(controller: self)
    }
    
    func didChangeMeetingData(obj: MeetingRepository.Meeting, data: MeetingRepository.MeetingData) {
        meetingData = data
        delegate?.didUpdateData(controller: self)
    }
}
