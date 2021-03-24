//
//  StatementViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class StatementViewController: NSViewController,
                               SpeechRecognizerDelegate,
                               StatementRepositoryDelegate,
                               NSCollectionViewDataSource,
                               NSCollectionViewDelegateFlowLayout {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var memberIconContainer: MemberIconContainer!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var startEndButton: NSButton!
    
    private let cellId = "StatementCollectionViewItem"
    private var workspaceId: String!
    private var meetingData: MeetingRepository.MeetingData!
    private let speechRecognizer = SpeechRecognizer.shared
    private var you: MeetingRepository.MeetingUserData?
    private var statementQueue: StatementQueue!
    private let statement = StatementRepository.Statement()
    private var statementDataList = [StatementRepository.StatementData]()
    private var calcHeightView: StatementCollectionViewItem!
    private var lastScrollIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statement.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        let nib = NSNib(nibNamed: "StatementCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
        calcHeightView = StatementCollectionViewItem()
        calcHeightView.instantiateFromNib()
    }

    override func viewDidAppear() {
        statement.listen(workspaceId: workspaceId, meetingId: meetingData.id)
    }
    
    override func viewWillDisappear() {
        stopRecognition()
        statement.unlisten()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? StatementShareViewController{
            vc.meetingName = meetingData.name
            vc.dataList = statementDataList
        }
    }
    
    private func startRecognition() {
        if you != nil {
            speechRecognizer.delegate = self
            speechRecognizer.start()
        }
    }
    
    private func stopRecognition() {
        if you != nil {
            speechRecognizer.stop()
            speechRecognizer.delegate = nil
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
    
    func setup(workspaceId: String, meetingData: MeetingRepository.MeetingData) {
        self.workspaceId = workspaceId
        self.meetingData = meetingData
        statementQueue = StatementQueue(workspaceId: workspaceId, meetingId: meetingData.id)
        titleLabel.stringValue = meetingData.name
        memberIconContainer.updateView(imageUrls: meetingData.userList.map { $0.iconImageUrl })
        if let currentUser = AuthUser.shared.currentUser() {
            you = meetingData.userList.first { $0.id == currentUser.uid }
        }
        startEndButton.isEnabled = you != nil
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
            statementDataList.insert(addedChange.data, at: addedChange.newIndex)
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
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let statementData = statementDataList[indexPath.item]
        return calcHeightView.calcSize(presenter: StatementCollectionViewItemPresenter(data: statementData, previousData: previousData(currentIndex: indexPath.item)))
    }
    
    @IBAction func pushStartEnd(_ sender: Any) {
        if startEndButton.state == .on {
            speechRecognizer.start()
        } else {
            speechRecognizer.stop()
        }
    }
}
