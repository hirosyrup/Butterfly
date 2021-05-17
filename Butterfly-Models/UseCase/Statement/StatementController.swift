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
    func didUpdateSpeechRecognizer(controller: StatementController, recognizerType: SpeechRecognizerType, canSelectRecognizer: Bool)
    func didUpdateAudioInputState(controller: StatementController, isAudioInputStart: Bool)
    func failedToUpdateAudioInputState(controller: StatementController, error: Error)
    func didUpdateRmsThreshold(controller: StatementController, threshold: Double)
    func didUpdateRms(controller: StatementController, rms: Double)
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
    
    let workspaceId: String
    private let speakerRecognizer: SpeakerRecognizer?
    private var speechRecognizer: SpeechRecognizer?
    private let audioSystem = AudioSystem.shared
    private var audioRecorder: AudioRecorder?
    private var isAudioInputStart = false
    private let observeBreakInStatements = ObserveBreakInStatements(limitTime: nil)
    private let autoCalcRmsThreshold: AutoCalcRmsThreshold
    private var currentSpeaker: MeetingUserRepository.MeetingUserData?
    private let statementQueue: StatementQueue
    private let meetingUser = MeetingUserRepository.User()
    private let meeting = MeetingRepository.Meeting()
    
    init(workspaceId: String, workspaceMLFileName: String?, initialMeetingData: MeetingRepository.MeetingData) {
        self.autoCalcRmsThreshold = AutoCalcRmsThreshold(initialThreshold: observeBreakInStatements.rmsThreshold)
        self.workspaceId = workspaceId
        var _speakerRecognizer: SpeakerRecognizer? = nil
        if let _workspaceMLFileName = workspaceMLFileName {
            let compiledFileName = MLFileLocalUrl.createCompiledModelFileName(modelFileName: _workspaceMLFileName)
            let compileModelFileUrl = MLFileLocalUrl.createLocalUrl().appendingPathComponent(compiledFileName)
            if FileManager.default.fileExists(atPath: compileModelFileUrl.path) {
                _speakerRecognizer = SpeakerRecognizer(compileModelFileUrl: compileModelFileUrl, format: audioSystem.inputFormat)
            }
        }
        self.speakerRecognizer = _speakerRecognizer
        self.meetingData = initialMeetingData
        self.statementQueue = StatementQueue(workspaceId: workspaceId, meetingId: initialMeetingData.id)
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
    
    private func setupSpeechRecognizer(you: MeetingUserRepository.MeetingUserData) {
        async({ _ -> PreferencesRepository.UserData in
            return try await(PreferencesRepository.User().findOrCreate(userId: you.userId))
        }).then({ userData in
            let advancedSettingData = userData.advancedSettingData
            var canSelectRecognizer = false
            var recognizerType = SpeechRecognizerType.apple
            if advancedSettingData.enableAmiVoice && !advancedSettingData.amiVoiceApiKey.isEmpty && !advancedSettingData.amiVoiceApiUrl.isEmpty {
                canSelectRecognizer = true
                recognizerType = userData.advancedSettingData.turnedOnByDefault ? .amiVoice : .apple
                let amiVoice = SpeechRecognizerAmiVoice.shared
                amiVoice.apiKey = advancedSettingData.amiVoiceApiKey
                amiVoice.apiUrlString = advancedSettingData.amiVoiceApiUrl
                amiVoice.apiEngine = advancedSettingData.amiVoiceEngine
            }
            SpeechRecognizerApple.shared.setupRecognizer(languageIdentifier: userData.language)
            self.updateSpeechRecognizer(speechRecognizerType: recognizerType)
            self.delegate?.didUpdateSpeechRecognizer(controller: self, recognizerType: recognizerType, canSelectRecognizer: canSelectRecognizer)
        })
    }
    
    private func updateAudioInputState() {
        guard you != nil else { return }
        let _isAudioInputStart = meetingData.isInMeeting()
        if isAudioInputStart != _isAudioInputStart {
            do {
                if _isAudioInputStart {
                    try startRecognition()
                    startRecord()
                } else {
                    stopRecognition()
                    stopRecord()
                    AudioUploaderQueue.shared.addUploader(workspaceId: workspaceId, meetingData: meetingData, meetingUserDataList: userList)
                }
                isAudioInputStart = _isAudioInputStart
                delegate?.didUpdateAudioInputState(controller: self, isAudioInputStart: _isAudioInputStart)
            } catch {
                delegate?.failedToUpdateAudioInputState(controller: self, error: error)
            }
        }
    }
    
    private func startRecord() {
        guard audioRecorder == nil else { return }
        if let startedAt = meetingData.startedAt {
            let interval = Date().timeIntervalSince1970 - startedAt.timeIntervalSince1970
            audioRecorder = AudioRecorder(startTime: Float(interval), meetingId: meetingData.id, inputFormat: audioSystem.inputFormat)
        }
    }
    
    private func stopRecord() {
        guard let recorder = audioRecorder else { return }
        recorder.stop()
        audioRecorder = nil
    }
    
    private func user(id: String?) -> MeetingUserRepository.MeetingUserData? {
        guard let _id = id else { return nil }
        return userList.first(where: { $0.userId == _id })
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
    
    func up() {
        speakerRecognizer?.delegate = self
        updateAudioInputState()
    }
    
    func down() {
        stopRecognition()
        stopRecord()
        exit()
    }
    
    func updateSpeechRecognizer(speechRecognizerType: SpeechRecognizerType) {
        speechRecognizer?.setDelegate(delegate: nil)
        switch speechRecognizerType {
        case .apple:
            speechRecognizer = SpeechRecognizerApple.shared
        case .amiVoice:
            speechRecognizer = SpeechRecognizerAmiVoice.shared
        }
        speechRecognizer?.setDelegate(delegate: self)
    }
    
    func startMeeting() throws {
        guard let _you = you else {
            throw NSError(domain: "You are not a participant in the meeting.", code: -1, userInfo: nil)
        }
        var updateData = meetingData
        if let index = userList.firstIndex(where: { $0.userId == _you.userId }) {
            updateData.startedAt = Date()
            var updateUserData = userList[index]
            updateUserData.isHost = true
            async({ _ -> MeetingUserRepository.MeetingUserData in
                try await(MeetingRepository.Meeting().update(workspaceId: self.workspaceId, meetingData: updateData))
                return try await(MeetingUserRepository.User().update(workspaceId: self.workspaceId, meetingId: updateData.id, meetingUserData: updateUserData))
            }).then { (_) in }
        }
    }
    
    func endMeeting() throws {
        guard you != nil else {
            throw NSError(domain: "You are not a participant in the meeting.", code: -1, userInfo: nil)
        }
        var updateData = meetingData
        updateData.endedAt = Date()
        async({ _ -> MeetingRepository.MeetingData in
            return try await(MeetingRepository.Meeting().update(workspaceId: self.workspaceId, meetingData: updateData))
        }).then { (_) in }
    }
    
    func didChangeAvailability(recognizer: SpeechRecognizer) {
        // TODO
    }
    
    func audioEngineStartError(obj: AudioSystem, error: Error) {
        delegate?.audioEngineStartError(controller: self, error: error)
    }
    
    func didNotCreateRecognitionRequest(recognizer: SpeechRecognizer, error: Error) {
        delegate?.didNotCreateRecognitionRequest(controller: self, error: error)
    }
    
    func didStartNewStatement(recognizer: SpeechRecognizer, id: String, speakerId: String?) {
        statementQueue.addNewStatement(uuid: id, user: user(id: speakerId))
    }
    
    func didUpdateStatement(recognizer: SpeechRecognizer, id: String, statement: String, speakerId: String?) {
        statementQueue.updateStatement(uuid: id, statement: statement, user: user(id: speakerId))
    }
    
    func didEndStatement(recognizer: SpeechRecognizer, id: String, statement: String, speakerId: String?) {
        statementQueue.endStatement(uuid: id, statement: statement, user: user(id: speakerId))
    }
    
    func didChangeMeetingUserDataList(obj: MeetingUserRepository.User, documentChanges: [RepositoryDocumentChange<MeetingUserRepository.MeetingUserData>]) {
        userList = meetingUser.createUserListFromDocumentChanges(prevUserList: userList, documentChanges: documentChanges)
        updateYou()
        enter()
        updateAudioInputState()
        delegate?.didUpdateData(controller: self)
    }
    
    func didChangeMeetingData(obj: MeetingRepository.Meeting, data: MeetingRepository.MeetingData) {
        meetingData = data
        updateAudioInputState()
        delegate?.didUpdateData(controller: self)
    }
    
    func didChangeSpeekingState(recognizer: SpeechRecognizer, isSpeeking: Bool) {
        if isSpeeking == false, let _speakerRecognizer = speakerRecognizer {
            _speakerRecognizer.resetSpeaker()
            currentSpeaker = nil
        }
    }
    
    func didChangeSpeaker(recognizer: SpeakerRecognizer, speakerUserId: String?) {
        if currentSpeaker != nil && currentSpeaker!.id != speakerUserId {
            speechRecognizer?.executeForceLineBreak()
        }
        currentSpeaker = userList.first { $0.userId == speakerUserId }
    }
    
    func notifyRenderBuffer(obj: AudioSystem, buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        speechRecognizer?.append(buffer: buffer, when: when, speakerId: currentSpeaker?.userId)
        observeBreakInStatements.checkBreakInStatements(buffer: buffer, when: when)
        if observeBreakInStatements.isSpeeking {
            speakerRecognizer?.analyze(buffer: buffer, when: when)
            audioRecorder?.write(buffer: buffer)
        } else {
            let emptyBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameCapacity)
            emptyBuffer?.frameLength = buffer.frameLength
            audioRecorder?.write(buffer: emptyBuffer!)
        }
        
        if observeBreakInStatements.isOverThreshold() {
            let threshold = autoCalcRmsThreshold.calcThreshold(rms: observeBreakInStatements.currentRms)
            observeBreakInStatements.rmsThreshold = threshold
            speechRecognizer?.setRmsThreshold(threshold: threshold)
            delegate?.didUpdateRmsThreshold(controller: self, threshold: Double(threshold))
        }
        
        delegate?.didUpdateRms(controller: self, rms: Double(observeBreakInStatements.currentRms))
    }
}
