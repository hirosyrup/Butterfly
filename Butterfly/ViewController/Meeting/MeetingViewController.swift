//
//  MeetingViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Cocoa

protocol MeetingViewControllerDelegate: class {
    func didClickItem(vc: MeetingViewController, workspaceId: String, workspaceMLFileName: String?, data: MeetingRepository.MeetingData)
}

class MeetingViewController: NSViewController,
                             MeetingCollectionViewControllerDelegate,
                             MeetingDateInputViewControllerDelegate,
                             MeetingCollectionDataProviderDelegate {
    
    @IBOutlet weak var workspacePopupButton: NSPopUpButton!
    @IBOutlet weak var dateFilterLabel: NSTextField!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var meetingCollectionViewContainer: NSView!
    @IBOutlet weak var filteringKeywordTextField: EditableNSTextField!
    
    private var userData: WorkspaceRepository.UserData?
    private var collectionViewController: MeetingCollectionViewController!
    
    weak var delegate: MeetingViewControllerDelegate?
    private var workspaceId = ""
    private let provider = MeetingCollectionDataProvider()
    
    class func create(delegate: MeetingViewControllerDelegate?) -> MeetingViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("MeetingViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! MeetingViewController
        vc.delegate = delegate
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        provider.delegate = self
        updateDateFilterLabel()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? MeetingCollectionViewController {
            vc.delegate = self
            collectionViewController = vc
        } else if let vc = segue.destinationController as? MeetingDateInputViewController {
            vc.delegate = self
        }
    }
    
    private func updateWorkspacePopupItems() {
        guard let _userData = userData else { return }
        workspacePopupButton.removeAllItems()
        workspacePopupButton.addItem(withTitle: "")
        workspacePopupButton.addItems(withTitles: _userData.workspaceList.map { $0.name })
        workspacePopupButton.selectItem(at: 1)
        updateWorkspacePopupItemTitle()
    }
    
    private func updateWorkspacePopupItemTitle() {
        guard let workspaceData = selectedWorkspaceData() else { return }
        workspacePopupButton.setTitle(workspaceData.name)
    }
    
    private func selectedWorkspaceData() -> WorkspaceRepository.WorkspaceData? {
        guard let _userData = userData else { return nil }
        let index = workspacePopupButton.indexOfSelectedItem - 1
        guard index >= 0 && _userData.workspaceList.count > index else { return nil }
        return _userData.workspaceList[workspacePopupButton.indexOfSelectedItem - 1]
    }
    
    private func reloadCollection() {
        guard let workspaceId = selectedWorkspaceData()?.id else { return }
        let userDefault = SearchOptionUserDefault.shared
        var startAt: Date? = nil
        var endAt: Date? = nil
        if userDefault.dateSegment() != 0 {
            startAt = userDefault.dateRangeStart()
            endAt = userDefault.dateRangeEnd()
        }
        changeSearchParams(workspaceId: workspaceId, startAt: startAt, endAt: endAt)
    }
    
    private func displayLoading(isDisplay: Bool) {
        if isDisplay {
            loadingIndicator.startAnimation(self)
        } else {
            loadingIndicator.stopAnimation(self)
        }
        meetingCollectionViewContainer.isHidden = isDisplay
    }
    
    private func changeSearchParams(workspaceId: String, startAt: Date?, endAt: Date?) {
        displayLoading(isDisplay: true)
        self.workspaceId = workspaceId
        provider.changeSearchParams(workspaceId: workspaceId, startAt: startAt, endAt: endAt)
    }
    
    private func updateDateFilterLabel() {
        dateFilterLabel.stringValue = MeetingViewDateFilterPresenter(userDefault: SearchOptionUserDefault.shared).dateFilterLabel()
    }
    
    func setup(userData: WorkspaceRepository.UserData) {
        self.userData = userData
        collectionViewController.userId = userData.id
        updateWorkspacePopupItems()
        reloadCollection()
        AudioUploaderQueue.shared.userId = userData.id
        AudioUploaderQueue.shared.listenMeeting(workspaceIds: userData.workspaceList.map { $0.id })
    }
    
    func didClickItem(vc: MeetingCollectionViewController, data: MeetingRepository.MeetingData) {
        guard let workspaceData = selectedWorkspaceData() else { return }
        delegate?.didClickItem(vc: self, workspaceId: workspaceData.id, workspaceMLFileName: workspaceData.mlFileName, data: data)
    }
    
    func willClose(vc: MeetingDateInputViewController) {
        updateDateFilterLabel()
        reloadCollection()
    }
    
    func didUpdateDataList(provider: MeetingCollectionDataProvider) {
        displayLoading(isDisplay: false)
        collectionViewController.update(meetingDataList: provider.displayDataList, workspaceId: workspaceId)
    }
    
    @IBAction func didChangePopup(_ sender: Any) {
        updateWorkspacePopupItemTitle()
        reloadCollection()
    }
    
    @IBAction func pushAddButton(_ sender: Any) {
        if let _userData = userData, let workspaceData = selectedWorkspaceData() {
            let vc = MeetingInputViewController.create(workspaceId: workspaceData.id, hostUserId: _userData.id, meetingData: nil)
            presentAsSheet(vc)
        }
    }
    
    @IBAction func didEnterFilteringKeywords(_ sender: Any) {
        provider.changeFilteringKeyword(keyword: filteringKeywordTextField.stringValue)
    }
}
