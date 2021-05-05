//
//  StatementController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/06.
//

import Foundation
import AVFoundation
import Hydra

class StatementController: SpeechRecognizerDelegate,
                           AudioSystemDelegate,
                           SpeakerRecognizerDelegate,
                           MeetingUserRepositoryDataListDelegate {
    private let workspaceId: String
    private let speakerRecognizer: SpeakerRecognizer?
    private let meetingData: MeetingRepository.MeetingData
    private let speechRecognizer: SpeechRecognizer?
    private let audioSystem = AudioSystem.shared
    private let audioRecorder: AudioRecorder?
    private var isAudioInputStart = false
    private let observeBreakInStatements = ObserveBreakInStatements(limitTime: nil)
    private let autoCalcRmsThreshold: AutoCalcRmsThreshold
    private var audioComposition: AVMutableComposition?
    private var userList = [MeetingUserRepository.MeetingUserData]()
    private var you: MeetingUserRepository.MeetingUserData?
    private var currentSpeaker: MeetingUserRepository.MeetingUserData?
    private var statementQueue: StatementQueue!
    private let meetingUser = MeetingUserRepository.User()
    
    init() {
        self.autoCalcRmsThreshold = AutoCalcRmsThreshold(initialThreshold: observeBreakInStatements.rmsThreshold)
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
    
    func listenData() {
        meetingUser.listen(workspaceId: workspaceId, meetingId: meetingData.id, dataListDelegate: self)
    }
    
    func unlistenData() {
        meetingUser.unlisten()
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
    
    func didChangeMeetingUserDataList(obj: MeetingUserRepository.User, documentChanges: [RepositoryDocumentChange<MeetingUserRepository.MeetingUserData>]) {
        userList = meetingUser.createUserListFromDocumentChanges(prevUserList: userList, documentChanges: documentChanges)
        updateYou()
        updateViews()
        enter()
        setupRecordAudioIfNeeded()
    }
}
