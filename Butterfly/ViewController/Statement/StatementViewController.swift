//
//  StatementViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa
import Hydra
import AVKit

class StatementViewController: NSViewController,
                               StatementRepositoryDelegate,
                               StatementControllerDelegate,
                               NSCollectionViewDataSource,
                               NSCollectionViewDelegateFlowLayout {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var MeetingMemberIconContainer: MeetingMemberIconContainer!
    @IBOutlet weak var collectionContainer: NSScrollView!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var startEndButton: NSButton!
    @IBOutlet weak var recordingLabel: NSBox!
    @IBOutlet weak var recordAudioDownloadIndicator: NSProgressIndicator!
    @IBOutlet weak var audioPlayerView: AVPlayerView!
    @IBOutlet weak var levelMeterContainer: NSView!
    @IBOutlet weak var speechRecognizerSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var speechRecognizerControlContainer: NSView!
    @IBOutlet weak var showCollectionButton: NSButton!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint?
    
    weak var levelMeter: StatementLevelMeter!
    
    private let cellId = "StatementCollectionViewItem"
    private var statementController: StatementController!
    private let statement = StatementRepository.Statement()
    private var statementDataList = [StatementRepository.StatementData]()
    private var lastScrollIndex = 0
    private let calcHeightHelper = CalcStatementCollectionItemHeight()
    private var collectionViewHeightConstant: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statement.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        let nib = NSNib(nibNamed: "StatementCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
        audioPlayerView.isHidden = true
        levelMeter = StatementLevelMeter.createFromNib(owner: nil)
        levelMeter.frame = levelMeterContainer.bounds
        levelMeterContainer.addSubview(levelMeter)
        collectionViewHeightConstant = collectionViewHeightConstraint?.constant ?? 0.0
        collectionViewHeightConstraint?.constant = 0.0
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        statementController.listenData()
    }
    
    override func viewDidAppear() {
        statement.listen(workspaceId: workspaceId, meetingId: meetingData.id)
        updateAudioInputState()
    }
    
    override func viewWillDisappear() {
        statementController.stopRecognition()
        stopRecord()
        statement.unlisten()
        exit()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        statementController.unlistenData()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? StatementShareViewController{
            vc.data = statementController.createStatementShareViewControllerData(statementDataList: statementDataList)
        }
    }

    private func previousData(currentIndex: Int) -> StatementRepository.StatementData? {
        let previousIndex = currentIndex - 1
        if previousIndex < 0 {
            return nil
        } else if statementDataList.count <= previousIndex {
            return nil
        } else {
            return statementDataList[previousIndex]
        }
    }
    
    private func updateViews() {
        let meetingData = statementController.meetingData
        let userList = statementController.userList
        let you = statementController.you
        let presenter = StatementViewControllerPresenter(meetingData: meetingData, meetingUserDataList: userList, you: you)
        titleLabel.stringValue = presenter.title()
        MeetingMemberIconContainer.updateView(presenters: presenter.meetingMemberIconPresenters())
        startEndButton.isHidden = presenter.isHiddenOfStartButton()
        startEndButton.state = presenter.startEndButtonState()
        recordingLabel.isHidden = presenter.isHiddenRecordingLabel()
        showCollectionButton.isHidden = presenter.isHiddenOfShowCollectionButton()
    }
    
    private func setupRecordAudioIfNeeded() {
        guard !userList.isEmpty else { return }
        if meetingData.startedAt != nil && meetingData.endedAt != nil {
            recordAudioDownloadIndicator.startAnimation(self)
            audioPlayerView.isHidden = true
            async({ _ -> AVMutableComposition in
                return try await(MergeAudio(meetingData: self.meetingData, meetingUserDataList: self.userList).merge())
            }).then({ composition in
                self.audioPlayerView.isHidden = false
                self.audioPlayerView.player = AVPlayer(playerItem: AVPlayerItem(asset: composition))
                self.audioComposition = composition
            }).catch { (error) in
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to download audio files. \(error.localizedDescription)").runModal()
            }.always(in: .main) {
                self.recordAudioDownloadIndicator.stopAnimation(self)
            }
        }
    }
    
    private func setupCollectionViewHeight() {
        if meetingData.startedAt != nil && meetingData.endedAt != nil {
            collectionViewHeightConstraint?.constant = collectionViewHeightConstant
            showCollectionButton.state = .on
            if let constraint = collectionViewHeightConstraint {
                collectionContainer.removeConstraint(constraint)
            }
        } else {
            collectionViewHeightConstraint?.constant = 0.0
            showCollectionButton.state = .off
        }
    }
    
    private func setupSpeechRecognizer(you: MeetingUserRepository.MeetingUserData) {
        speechRecognizerControlContainer.isHidden = true
        async({ _ -> PreferencesRepository.UserData in
            return try await(PreferencesRepository.User().findOrCreate(userId: you.userId))
        }).then({ userData in
            let advancedSettingData = userData.advancedSettingData
            if advancedSettingData.enableAmiVoice && !advancedSettingData.amiVoiceApiKey.isEmpty && !advancedSettingData.amiVoiceApiUrl.isEmpty {
                self.speechRecognizerControlContainer.isHidden = false
                self.speechRecognizerSegmentedControl.selectedSegment = userData.advancedSettingData.turnedOnByDefault ? 1 : 0
                let amiVoice = SpeechRecognizerAmiVoice.shared
                amiVoice.apiKey = advancedSettingData.amiVoiceApiKey
                amiVoice.apiUrlString = advancedSettingData.amiVoiceApiUrl
                amiVoice.apiEngine = advancedSettingData.amiVoiceEngine
            }
            SpeechRecognizerApple.shared.setupRecognizer(languageIdentifier: userData.language)
            self.updateSpeechRecognizer()
        })
    }
    
    private func updateSpeechRecognizer() {
        speechRecognizer?.setDelegate(delegate: nil)
        switch speechRecognizerSegmentedControl.selectedSegment {
        case 0:
            speechRecognizer = SpeechRecognizerApple.shared
        case 1:
            speechRecognizer = SpeechRecognizerAmiVoice.shared
        default:
            break
        }
        speechRecognizer?.setDelegate(delegate: self)
    }
    
    private func startAudioInput(userId: String, isHost: Bool) {
        guard var updateData = meetingData else { return }
        if let index = userList.firstIndex(where: { $0.userId == userId }) {
            updateData.startedAt = Date()
            var updateUserData = userList[index]
            updateUserData.isHost = isHost
            async({ _ -> MeetingUserRepository.MeetingUserData in
                try await(MeetingRepository.Meeting().update(workspaceId: self.workspaceId, meetingData: updateData))
                return try await(MeetingUserRepository.User().update(workspaceId: self.workspaceId, meetingId: updateData.id, meetingUserData: updateUserData))
            }).then { (_) in }
        }
    }
    
    private func endAudioInput() {
        guard var updateData = meetingData else { return }
        updateData.endedAt = Date()
        async({ _ -> MeetingRepository.MeetingData in
            return try await(MeetingRepository.Meeting().update(workspaceId: self.workspaceId, meetingData: updateData))
        }).then { (_) in }
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
    
    private func updateAudioInputState() {
        guard you != nil else { return }
        let _isAudioInputStart = meetingData.startedAt != nil && meetingData.endedAt == nil
        if isAudioInputStart != _isAudioInputStart {
            do {
                if _isAudioInputStart {
                    try statementController.startRecognition()
                    startRecord()
                } else {
                    statementController.stopRecognition()
                    stopRecord()
                    AudioUploaderQueue.shared.addUploader(workspaceId: workspaceId, meetingData: meetingData, meetingUserDataList: userList)
                }
                levelMeter.setEnable(enabled: _isAudioInputStart)
                isAudioInputStart = _isAudioInputStart
            } catch {
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start speaker recognization. \(error.localizedDescription)").runModal()
            }
        }
    }
    
    private func reloadCollectionView() {
        collectionView.reloadData()
        if !statementDataList.isEmpty {
            collectionView.animator().scrollToItems(at: [IndexPath(item: statementDataList.count - 1, section: 0)], scrollPosition: .bottom)
        }
    }
    
    func setup(workspaceId: String, workspaceMLFileName: String?, meetingData: MeetingRepository.MeetingData) {
        statementController = StatementController(workspaceId: workspaceId, workspaceMLFileName: workspaceMLFileName, initialMeetingData: meetingData)
        updateViews()
        setupRecordAudioIfNeeded()
        setupCollectionViewHeight()
    }
    
//    func updateMeetingData(meetingData: MeetingRepository.MeetingData) {
//        self.meetingData = meetingData
//        updateAudioInputState()
//        updateViews()
//        setupRecordAudioIfNeeded()
//        setupCollectionViewHeight()
//    }
    
    func notifyRenderBuffer(obj: AudioSystem, buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        speechRecognizer?.append(buffer: buffer, when: when)
        speakerRecognizer?.analyze(buffer: buffer, when: when)
        observeBreakInStatements.checkBreakInStatements(buffer: buffer, when: when)
        if observeBreakInStatements.isSpeeking {
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
            levelMeter.updateThreshold(threshold: Double(threshold))
        }
        
        levelMeter.setRms(rms: Double(observeBreakInStatements.currentRms))
    }
    
    func didNotCreateRecognitionRequest(controller: StatementController, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "\(error.localizedDescription)").runModal()
    }
    
    func audioEngineStartError(controller: StatementController, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start audio engine. \(error.localizedDescription)").runModal()
    }
    
    func didChangeSpeekingState(recognizer: SpeechRecognizer, isSpeeking: Bool) {
        if isSpeeking == false, let _speakerRecognizer = speakerRecognizer {
            _speakerRecognizer.resetSpeaker()
            currentSpeaker = nil
        }
    }
    
    func didChangeStatementData(obj: StatementRepository.Statement, documentChanges: [RepositoryDocumentChange<StatementRepository.StatementData>]) {
        let modifieds = documentChanges.filter { $0.type == .modified }
        modifieds.forEach { (modified) in
            if let index = statementDataList.firstIndex(where: { $0.id == modified.data.id }) {
                statementDataList[index] = modified.data
            }
        }
        
        let removesIds = documentChanges.filter { $0.type == .removed }.map { $0.data.id }
        var removedStatementList = [StatementRepository.StatementData]()
        statementDataList.forEach {
            if !removesIds.contains($0.id) {
                removedStatementList.append($0)
            }
        }
        statementDataList = removedStatementList
        
        let addeds = documentChanges.filter { $0.type == .added }
        addeds.forEach { (addedChange) in
            if addedChange.newIndex >= statementDataList.count {
                statementDataList.append(addedChange.data)
            } else {
                statementDataList.insert(addedChange.data, at: addedChange.newIndex)
            }
        }
        
        if showCollectionButton.state == .on {
            reloadCollectionView()
        }
    }
    
//    func didChangeMeetingUserDataList(obj: MeetingUserRepository.User, documentChanges: [RepositoryDocumentChange<MeetingUserRepository.MeetingUserData>]) {
//        userList = meetingUser.createUserListFromDocumentChanges(prevUserList: userList, documentChanges: documentChanges)
//        updateYou()
//        updateViews()
//        enter()
//        setupRecordAudioIfNeeded()
//    }
    
    func didChangeSpeaker(recognizer: SpeakerRecognizer, speakerUserId: String?) {
        if currentSpeaker != nil && currentSpeaker!.id != speakerUserId {
            speechRecognizer?.executeForceLineBreak()
        }
        currentSpeaker = userList.first { $0.id == speakerUserId }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return statementDataList.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! StatementCollectionViewItem
        let statementData = statementDataList[indexPath.item]
        item.updateView(presenter: StatementCollectionViewItemPresenter(data: statementData, previousData: previousData(currentIndex: indexPath.item)))
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectItems(at: indexPaths)
        guard let indexPath = indexPaths.first else { return }
        guard let startedAt = meetingData.startedAt else { return }
        let statementData = statementDataList[indexPath.item]
        let diff = statementData.createdAt.timeIntervalSince1970 - startedAt.timeIntervalSince1970
        audioPlayerView.player?.seek(to: CMTime(seconds: diff, preferredTimescale: 1000))
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let statementData = statementDataList[indexPath.item]
        let presenter = StatementCollectionViewItemPresenter(data: statementData, previousData: previousData(currentIndex: indexPath.item))
        return calcHeightHelper.calcSize(index: indexPath.item, presenter: presenter)
    }
    
    @IBAction func pushStartEnd(_ sender: Any) {
        if startEndButton.state == .on {
            if let _you = you {
                startAudioInput(userId: _you.userId, isHost: true)
            }
        } else {
            endAudioInput()
        }
    }
    
    @IBAction func changeSpeechRecognizerSetting(_ sender: Any) {
        updateSpeechRecognizer()
    }
    
    @IBAction func pushShowCollectionButton(_ sender: Any) {
        let buttonState = showCollectionButton.state
        NSAnimationContext.runAnimationGroup { (context) in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.collectionViewHeightConstraint?.animator().constant = buttonState == .on ? collectionViewHeightConstant : 0.0
        } completionHandler: {
            if buttonState == .on {
                self.reloadCollectionView()
            }
        }
    }
}
