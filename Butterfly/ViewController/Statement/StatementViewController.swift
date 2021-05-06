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
    private var audioComposition: AVMutableComposition?
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
        speechRecognizerControlContainer.isHidden = true
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
        statementController.close()
        statement.unlisten()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        statementController.unlistenData()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? StatementShareViewController {
            let data = StatementShareViewControllerData(
                workspaceId: statementController.workspaceId,
                meetingData: statementController.meetingData,
                statementDataList: statementDataList,
                audioComposition: audioComposition
            )
            vc.data = data
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
        let userList = statementController.userList
        guard !userList.isEmpty else { return }
        let meetingData = statementController.meetingData
        if meetingData.isFinished() {
            recordAudioDownloadIndicator.startAnimation(self)
            audioPlayerView.isHidden = true
            async({ _ -> AVMutableComposition in
                return try await(MergeAudio(meetingData: meetingData, meetingUserDataList: userList).merge())
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
        let meetingData = statementController.meetingData
        if meetingData.isFinished() {
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
    
    private func updateSpeechRecognizer() {
        guard let speechRecognizerType = SpeechRecognizerType(rawValue: speechRecognizerSegmentedControl.selectedSegment) else { return }
        statementController.updateSpeechRecognizer(speechRecognizerType: speechRecognizerType)
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
    
    func didNotCreateRecognitionRequest(controller: StatementController, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "\(error.localizedDescription)").runModal()
    }
    
    func audioEngineStartError(controller: StatementController, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start audio engine. \(error.localizedDescription)").runModal()
    }
    
    func didUpdateData(controller: StatementController) {
        setupRecordAudioIfNeeded()
        updateViews()
        setupCollectionViewHeight()
    }
    
    func didUpdateSpeechRecognizer(controller: StatementController, recognizerType: SpeechRecognizerType, canSelectRecognizer: Bool) {
        speechRecognizerControlContainer.isHidden = canSelectRecognizer
        speechRecognizerSegmentedControl.selectedSegment = recognizerType.rawValue
    }
    
    func didUpdateAudioInputState(controller: StatementController, isAudioInputStart: Bool) {
        levelMeter.setEnable(enabled: isAudioInputStart)
    }
    
    func failedToUpdateAudioInputState(controller: StatementController, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start speaker recognization. \(error.localizedDescription)").runModal()
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
        guard let startedAt = statementController.meetingData.startedAt else { return }
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
        do {
            if startEndButton.state == .on {
                try statementController.startMeeting()
            } else {
                try statementController.endMeeting()
            }
        } catch {
            AlertBuilder.createErrorAlert(title: "Error", message: error.localizedDescription).runModal()
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
