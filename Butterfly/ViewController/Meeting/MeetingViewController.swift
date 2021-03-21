//
//  MeetingViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Cocoa

class MeetingViewController: NSViewController {
    
    @IBOutlet weak var workspacePopupButton: NSPopUpButton!
    @IBOutlet weak var noMeetingsLabel: NSTextField!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var collectionView: NSCollectionView!
    private var userData: MeetingRepository.UserData?
    
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
        guard let _userData = userData else { return }
        workspacePopupButton.setTitle(_userData.workspaceList[workspacePopupButton.indexOfSelectedItem - 1].name)
    }
    
    func setup(userData: MeetingRepository.UserData) {
        self.userData = userData
        updateWorkspacePopupItems()
    }
    
    @IBAction func didChangePopup(_ sender: Any) {
        updateWorkspacePopupItemTitle()
    }
}
