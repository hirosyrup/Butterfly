//
//  StatementViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa
import Hydra
import AVFoundation
import AVKit

class StatementViewController: NSViewController,
                               SpeechRecognizerDelegate,
                               AudioSystemDelegate,
                               StatementRepositoryDelegate,
                               NSCollectionViewDataSource,
                               NSCollectionViewDelegateFlowLayout {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var MeetingMemberIconContainer: MeetingMemberIconContainer!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var startEndButton: NSButton!
    @IBOutlet weak var recordingLabel: NSBox!
    @IBOutlet weak var recordAudioDownloadIndicator: NSProgressIndicator!
    @IBOutlet weak var audioPlayerView: AVPlayerView!
    
    private let cellId = "StatementCollectionViewItem"
    private var workspaceId: String!
    private var meetingData: MeetingRepository.MeetingData!
    private let speechRecognizer = SpeechRecognizer.shared
    private let audioSystem = AudioSystem.shared
    private var you: MeetingRepository.MeetingUserData?
    private var statementQueue: StatementQueue!
    private let statement = StatementRepository.Statement()
    private var statementDataList = [StatementRepository.StatementData]()
    private var lastScrollIndex = 0
    private var audioRecorder: AudioRecorder?
    private var isAudioInputStart = false
    private let observeBreakInStatements = ObserveBreakInStatements(bufferSize: AudioBufferSize.bufferSize, limitTime: nil)
    private var autoCalcRmsThreshold: AutoCalcRmsThreshold!
    private var audioComposition: AVMutableComposition?
    private let calcHeightHelper = CalcStatementCollectionItemHeight()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statement.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        let nib = NSNib(nibNamed: "StatementCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
        audioPlayerView.isHidden = true
        autoCalcRmsThreshold = AutoCalcRmsThreshold(initialThreshold: observeBreakInStatements.rmsThreshold)
    }

    override func viewDidAppear() {
        statement.listen(workspaceId: workspaceId, meetingId: meetingData.id)
        updateAudioInputState()
    }
    
    override func viewWillDisappear() {
        stopRecognition()
        stopRecord()
        statement.unlisten()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? StatementShareViewController{
            vc.workspaceId = workspaceId
            vc.meetingData = meetingData
            vc.dataList = statementDataList
            vc.audioComposition = audioComposition
        }
    }
    
    private func startRecognition() {
        speechRecognizer.delegate = self
        audioSystem.delegate = self
        audioSystem.start()
    }
    
    private func stopRecognition() {
        audioSystem.stop()
        speechRecognizer.delegate = nil
        audioSystem.delegate = nil
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
        if let currentUser = AuthUser.shared.currentUser() {
            you = meetingData.userList.first { $0.id == currentUser.uid }
        }
        let presenter = StatementViewControllerPresenter(meetingData: meetingData, you: you)
        titleLabel.stringValue = presenter.title()
        MeetingMemberIconContainer.updateView(presenters: presenter.meetingMemberIconPresenters())
        startEndButton.isHidden = presenter.isHiddenOfStartButton()
        startEndButton.state = presenter.startEndButtonState()
        recordingLabel.isHidden = presenter.isHiddenRecordingLabel()
    }
    
    private func setupRecordAudioIfNeeded() {
        if meetingData.startedAt != nil && meetingData.endedAt != nil {
            recordAudioDownloadIndicator.startAnimation(self)
            audioPlayerView.isHidden = true
            async({ _ -> AVMutableComposition in
                return try await(MergeAudio(meetingData: self.meetingData).merge())
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
    
    private func startAudioInput(userId: String, isHost: Bool) {
        guard var updateData = meetingData else { return }
        if let index = updateData.userList.firstIndex(where: { $0.id == userId }) {
            updateData.startedAt = Date()
            updateData.userList[index].isHost = isHost
            async({ _ -> MeetingRepository.MeetingUserData in
                return try await(MeetingRepository.Meeting().updateUser(workspaceId: self.workspaceId, meetingData: updateData, userIndex: index))
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
            if _isAudioInputStart {
                startRecognition()
                startRecord()
            } else {
                stopRecognition()
                stopRecord()
                AudioUploaderQueue.shared.addUploader(workspaceId: workspaceId, meetingData: meetingData)
            }
            isAudioInputStart = _isAudioInputStart
        }
    }
    
    func setup(workspaceId: String, meetingData: MeetingRepository.MeetingData) {
        self.workspaceId = workspaceId
        self.meetingData = meetingData
        statementQueue = StatementQueue(workspaceId: workspaceId, meetingId: meetingData.id)
        updateViews()
        setupRecordAudioIfNeeded()
    }
    
    func updateMeetingData(meetingData: MeetingRepository.MeetingData) {
        self.meetingData = meetingData
        updateAudioInputState()
        updateViews()
        setupRecordAudioIfNeeded()
    }
    
    func audioEngineStartError(obj: AudioSystem, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start audio engine. \(error.localizedDescription)").runModal()
    }
    
    func notifyRenderBuffer(obj: AudioSystem, buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        speechRecognizer.append(buffer: buffer, when: when)
        observeBreakInStatements.checkBreakInStatements(buffer: buffer, when: when)
        if observeBreakInStatements.isSpeeking {
            audioRecorder?.write(buffer: buffer)
        } else {
            let emptyBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameCapacity)
            emptyBuffer?.frameLength = buffer.frameLength
            audioRecorder?.write(buffer: emptyBuffer!)
        }
        
        if observeBreakInStatements.isOverThreshold() {
            observeBreakInStatements.rmsThreshold = autoCalcRmsThreshold.calcThreshold(rms: observeBreakInStatements.currentRms)
        }
    }
    
    func didChangeAvailability(recognizer: SpeechRecognizer) {
        // TODO
    }
    
    func didNotCreateRecognitionRequest(recognizer: SpeechRecognizer, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "\(error.localizedDescription)").runModal()
    }
    
    func didStartNewStatement(recognizer: SpeechRecognizer, id: String) {
        if let _you = you {
            statementQueue.addNewStatement(uuid: id, user: _you)
        }
    }
    
    func didUpdateStatement(recognizer: SpeechRecognizer, id: String, statement: String) {
        statementQueue.updateStatement(uuid: id, statement: statement)
    }
    
    func didEndStatement(recognizer: SpeechRecognizer, id: String, statement: String) {
        statementQueue.endStatement(uuid: id, statement: statement)
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
        
        collectionView.reloadData()
        if !statementDataList.isEmpty {
            collectionView.animator().scrollToItems(at: [IndexPath(item: statementDataList.count - 1, section: 0)], scrollPosition: .bottom)
        }
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
                startAudioInput(userId: _you.id, isHost: true)
            }
        } else {
            endAudioInput()
        }
    }
}
