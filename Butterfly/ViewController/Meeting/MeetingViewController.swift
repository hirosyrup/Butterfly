//
//  MeetingViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Cocoa

class MeetingViewController: NSViewController,
                             MeetingInputViewControllerDelegate {
    
    @IBOutlet weak var workspacePopupButton: NSPopUpButton!
    @IBOutlet weak var noMeetingsLabel: NSTextField!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var collectionView: NSCollectionView!
    private var userData: WorkspaceRepository.UserData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func updateViews() {
        noMeetingsLabel.isHidden = true
        loadingIndicator.isHidden = true
        collectionView.isHidden = true
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
        return _userData.workspaceList[workspacePopupButton.indexOfSelectedItem - 1]
    }
    
    func setup(userData: WorkspaceRepository.UserData) {
        self.userData = userData
        updateWorkspacePopupItems()
    }
    
    func willDismiss(vc: MeetingInputViewController) {
        
    }
    
    @IBAction func didChangePopup(_ sender: Any) {
        updateWorkspacePopupItemTitle()
    }
    
    @IBAction func pushAddButton(_ sender: Any) {
        if let workspaceData = selectedWorkspaceData() {
            let vc = MeetingInputViewController.create(workspaceId: workspaceData.id, meetingData: nil, delegate: self)
            presentAsSheet(vc)
        }
    }
}
