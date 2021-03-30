//
//  MeetingViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Cocoa

protocol MeetingViewControllerDelegate: class {
    func didClickItem(vc: MeetingViewController, workspaceId: String, data: MeetingRepository.MeetingData)
}

class MeetingViewController: NSViewController,
                             MeetingCollectionViewControllerDelegate {
    
    @IBOutlet weak var workspacePopupButton: NSPopUpButton!
    private var userData: WorkspaceRepository.UserData?
    private var collectionViewController: MeetingCollectionViewController!
    
    weak var delegate: MeetingViewControllerDelegate?
    
    class func create(delegate: MeetingViewControllerDelegate?) -> MeetingViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("MeetingViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! MeetingViewController
        vc.delegate = delegate
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? MeetingCollectionViewController {
            vc.delegate = self
            collectionViewController = vc
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
        guard index > 0 && _userData.workspaceList.count > index else { return nil }
        return _userData.workspaceList[workspacePopupButton.indexOfSelectedItem - 1]
    }
    
    private func reloadCollection() {
        guard let workspaceId = selectedWorkspaceData()?.id else { return }
        collectionViewController.changeWorkspaceId(workspaceId: workspaceId)
    }
    
    func setup(userData: WorkspaceRepository.UserData) {
        self.userData = userData
        collectionViewController.userId = userData.id
        updateWorkspacePopupItems()
        reloadCollection()
    }
    
    func didClickItem(vc: MeetingCollectionViewController, data: MeetingRepository.MeetingData) {
        guard let workspaceData = selectedWorkspaceData() else { return }
        delegate?.didClickItem(vc: self, workspaceId: workspaceData.id, data: data)
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
}
