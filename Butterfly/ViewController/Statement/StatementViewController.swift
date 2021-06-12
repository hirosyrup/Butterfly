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
                               StatementCollectionDataProviderDelegate,
                               StatementControllerDelegate,
                               AudioPlayerMenuDelegate,
                               StatementSwitchesViewControllerDelegate,
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
    @IBOutlet weak var searchFieldContainer: NSView!
    @IBOutlet weak var levelMeterContainer: NSView!
    @IBOutlet weak var showCollectionButton: NSButton!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var switchOptionButton: NSButton!
    @IBOutlet weak var filteringKeywordTextField: EditableNSTextField!
    @IBOutlet weak var filterHitCountLabel: NSTextField!
    @IBOutlet weak var filterResultUpButton: NSButton!
    @IBOutlet weak var filterResultDownButton: NSButton!
    
    weak var levelMeter: StatementLevelMeter!
    
    private let cellId = "StatementCollectionViewItem"
    private var statementController: StatementController!
    private var dataProvider: StatementCollectionDataProvider!
    private var audioComposition: AVMutableComposition?
    private var lastScrollIndex = 0
    private let calcHeightHelper = CalcStatementCollectionItemHeight()
    private var collectionViewHeightConstant: CGFloat = 0.0
    private let audioPlayerMenu = AudioPlayerMenu()
    private var canSelectRecognizer: Bool?
    private var isAutoScroll = StatementOptionUserDefault.shared.isAutoScroll()
    private var playerIsReadyForDisplayObserver: NSKeyValueObservation?
    private var filterCurrentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioPlayerMenu.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        let nib = NSNib(nibNamed: "StatementCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
        audioPlayerView.isHidden = true
        audioPlayerView.actionPopUpButtonMenu = audioPlayerMenu.createMenu()
        levelMeter = StatementLevelMeter.createFromNib(owner: nil)
        levelMeter.frame = levelMeterContainer.bounds
        levelMeterContainer.addSubview(levelMeter)
        collectionViewHeightConstant = collectionViewHeightConstraint.constant
        collectionViewHeightConstraint.constant = 0.0
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        statementController.listenData()
    }
    
    override func viewDidAppear() {
        statementController.up()
        dataProvider.listenData()
    }
    
    override func viewWillDisappear() {
        statementController.down()
        dataProvider.unlistenData()
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
                statementDataList: dataProvider.statementDataList,
                audioComposition: audioComposition
            )
            vc.data = data
        } else if let vc = segue.destinationController as? StatementSwitchesViewController {
            vc.delegate = self
            vc.setup(initialRecognizerType: statementController.recognizerType, canSelectRecognizer: canSelectRecognizer ?? false, isMutingSilentPart: statementController.isMutingSilentPart, isAutoScroll: isAutoScroll)
        }
    }

    private func previousData(currentIndex: Int) -> StatementRepository.StatementData? {
        let previousIndex = currentIndex - 1
        if previousIndex < 0 {
            return nil
        } else if dataProvider.statementDataList.count <= previousIndex {
            return nil
        } else {
            return dataProvider.statementDataList[previousIndex]
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
        switchOptionButton.isHidden = presenter.isHiddenSwitchOptionButton()
        levelMeterContainer.isHidden = presenter.isHiddenLevelMeter()
        searchFieldContainer.isHidden = presenter.isHiddenSearchField()
    }
    
    private func setupRecordAudioIfNeeded(isUploadingAudio: Bool) {
        let userList = statementController.userList
        guard !userList.isEmpty else { return }
        let meetingData = statementController.meetingData
        if meetingData.isFinished() {
            recordAudioDownloadIndicator.startAnimation(self)
            audioPlayerView.isHidden = true
            if isUploadingAudio {
                return
            }
            async({ _ -> AVMutableComposition in
                return try await(MergeAudio(meetingData: meetingData, meetingUserDataList: userList).merge())
            }).then({ composition in
                // 画面を開いてすぐplayerにセットすると何故か現在の再生時間が表示されなくなる
                // 詳細な条件は不明。とりあえず少し間を置いてセットすることで回避。
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.recordAudioDownloadIndicator.stopAnimation(self)
                    self.audioPlayerView.isHidden = false
                    let playerItem = AVPlayerItem(asset: composition)
                    self.audioPlayerView.player = AVPlayer(playerItem: playerItem)
                    self.audioComposition = composition
                }
            }).catch { (error) in
                self.recordAudioDownloadIndicator.stopAnimation(self)
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to download audio files. \(error.localizedDescription)").runModal()
            }
        }
    }
    
    private func setupCollectionViewSize() {
        let meetingData = statementController.meetingData
        if meetingData.isFinished() {
            collectionViewHeightConstraint.constant = collectionViewHeightConstant
            collectionViewWidthConstraint.constant = 600.0
            collectionContainer.layoutSubtreeIfNeeded()
            reloadCollectionView()
            showCollectionButton.state = .on
        } else {
            collectionViewHeightConstraint.constant = showCollectionButton.state == .on ? collectionViewHeightConstant : 0.0
        }
    }
    
    private func reloadCollectionView() {
        collectionView.reloadData()
        if !dataProvider.statementDataList.isEmpty && isAutoScroll {
            collectionView.animator().scrollToItems(at: [IndexPath(item: dataProvider.statementDataList.count - 1, section: 0)], scrollPosition: .bottom)
        }
    }
    
    private func scrollToItem(index: Int) {
        let ctx = NSAnimationContext.current
        ctx.allowsImplicitAnimation = true
        collectionView.animator().scrollToItems(at: [IndexPath(item: index, section: 0)], scrollPosition: .top)
    }
    
    private func addValueToFilterCurrentIndex(value: Int) {
        let hitIndices = dataProvider.filterHitIndices
        filterCurrentIndex = filterCurrentIndex + value
        if filterCurrentIndex >= hitIndices.count {
            filterCurrentIndex = 0
        } else if filterCurrentIndex < 0 {
            filterCurrentIndex = hitIndices.count - 1
        }
    }
    
    private func updateFilterHitCountLabel() {
        let hitIndices = dataProvider.filterHitIndices
        let hitCount = hitIndices.count
        filterHitCountLabel.stringValue = hitCount == 0 ? "" : "\(filterCurrentIndex + 1) / \(hitCount)"
    }
    
    func setup(workspaceId: String, workspaceMLFileName: String?, meetingData: MeetingRepository.MeetingData) {
        statementController = StatementController(workspaceId: workspaceId, workspaceMLFileName: workspaceMLFileName, initialMeetingData: meetingData, isMutingSilentPart: StatementOptionUserDefault.shared.isMutingSilentPart())
        statementController.delegate = self
        dataProvider = StatementCollectionDataProvider(workspaceId: workspaceId, meetingId: meetingData.id)
        dataProvider.delegate = self
        updateViews()
        setupRecordAudioIfNeeded(isUploadingAudio: false)
        setupCollectionViewSize()
    }
    
    func didNotCreateRecognitionRequest(controller: StatementController, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "\(error.localizedDescription)").runModal()
    }
    
    func audioEngineStartError(controller: StatementController, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start audio engine. \(error.localizedDescription)").runModal()
    }
    
    func didUpdateData(controller: StatementController) {
        let you = controller.you
        setupRecordAudioIfNeeded(isUploadingAudio: you != nil && you!.audioFileName == nil)
        updateViews()
        setupCollectionViewSize()
    }
    
    func didUpdateSpeechRecognizer(controller: StatementController, canSelectRecognizer: Bool) {
        self.canSelectRecognizer = canSelectRecognizer
    }
    
    func didUpdateAudioInputState(controller: StatementController, isAudioInputStart: Bool) {
        levelMeter.setEnable(enabled: isAudioInputStart)
    }
    
    func failedToUpdateAudioInputState(controller: StatementController, error: Error) {
        AlertBuilder.createErrorAlert(title: "Error", message: "Failed to start speaker recognization. \(error.localizedDescription)").runModal()
    }
    
    func didUpdateRmsThreshold(controller: StatementController, threshold: Double) {
        levelMeter.updateThreshold(threshold: threshold)
    }
    
    func didUpdateRms(controller: StatementController, rms: Double) {
        levelMeter.setRms(rms: rms)
    }
    
    func didUpdateDataList(provider: StatementCollectionDataProvider) {
        if showCollectionButton.state == .on {
            reloadCollectionView()
        }
    }
    
    func didChangePlaybackRate(menu: AudioPlayerMenu, rate: Float) {
        audioPlayerView.player?.rate = rate
    }
    
    func didChangeSpeechRecognizerType(vc: StatementSwitchesViewController, recognizerType: SpeechRecognizerType) {
        statementController.updateSpeechRecognizer(speechRecognizerType: recognizerType)
    }
    
    func didChangeIsMutingSilentPart(vc: StatementSwitchesViewController, isMutingSilentPart: Bool) {
        StatementOptionUserDefault.shared.saveMutingSilentPart(isMutingSilentPart: isMutingSilentPart)
        statementController.isMutingSilentPart = isMutingSilentPart
    }
    
    func didChangeIsAutoScroll(vc: StatementSwitchesViewController, isAutoScroll: Bool) {
        StatementOptionUserDefault.shared.saveAutoScroll(isAutoScroll: isAutoScroll)
        self.isAutoScroll = isAutoScroll
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataProvider.statementDataList.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! StatementCollectionViewItem
        let statementData = dataProvider.statementDataList[indexPath.item]
        item.updateView(presenter: StatementCollectionViewItemPresenter(data: statementData, previousData: previousData(currentIndex: indexPath.item), filterKeyword: filteringKeywordTextField.stringValue), width: collectionViewWidthConstraint.constant)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        collectionView.deselectItems(at: indexPaths)
        guard let indexPath = indexPaths.first else { return }
        guard let startedAt = statementController.meetingData.startedAt else { return }
        let statementData = dataProvider.statementDataList[indexPath.item]
        let diff = statementData.createdAt.timeIntervalSince1970 - startedAt.timeIntervalSince1970
        audioPlayerView.player?.seek(to: CMTime(seconds: diff, preferredTimescale: 1000))
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let statementData = dataProvider.statementDataList[indexPath.item]
        let presenter = StatementCollectionViewItemPresenter(data: statementData, previousData: previousData(currentIndex: indexPath.item), filterKeyword: filteringKeywordTextField.stringValue)
        return calcHeightHelper.calcSize(index: indexPath.item, presenter: presenter, width: collectionViewWidthConstraint.constant)
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
    
    @IBAction func pushShowCollectionButton(_ sender: Any) {
        let buttonState = showCollectionButton.state
        NSAnimationContext.runAnimationGroup { (context) in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.collectionViewHeightConstraint.animator().constant = buttonState == .on ? collectionViewHeightConstant : 0.0
        } completionHandler: {
            if buttonState == .on {
                self.reloadCollectionView()
            }
        }
    }
    
    @IBAction func didEnterFilteringKeywords(_ sender: Any) {
        let previousHitIndices = dataProvider.filterHitIndices
        let keyword = filteringKeywordTextField.stringValue
        dataProvider.updateFilterHitIndices(keyword: keyword)
        let hitIndices = dataProvider.filterHitIndices
        let hitCount = hitIndices.count
        filterCurrentIndex = 0
        updateFilterHitCountLabel()
        
        collectionView.reloadItems(at: Set(previousHitIndices.map { IndexPath(item: $0, section: 0) }))
        collectionView.reloadItems(at: Set(hitIndices.map { IndexPath(item: $0, section: 0) }))
        
        let isHit = hitCount != 0
        if isHit {
            scrollToItem(index: hitIndices[filterCurrentIndex])
        }
        filterResultUpButton.isEnabled = isHit
        filterResultDownButton.isEnabled = isHit
    }
    
    @IBAction func pushFilterResultUp(_ sender: Any) {
        addValueToFilterCurrentIndex(value: -1)
        scrollToItem(index: dataProvider.filterHitIndices[filterCurrentIndex])
        updateFilterHitCountLabel()
    }
    
    @IBAction func pushFilterResultDown(_ sender: Any) {
        addValueToFilterCurrentIndex(value: 1)
        scrollToItem(index: dataProvider.filterHitIndices[filterCurrentIndex])
        updateFilterHitCountLabel()
    }
}
