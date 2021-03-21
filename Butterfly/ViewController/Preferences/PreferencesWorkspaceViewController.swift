//
//  PreferencesWorkspaceViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/17.
//

import Cocoa
import Hydra

class PreferencesWorkspaceViewController: NSViewController,
                                          NSCollectionViewDataSource,
                                          NSCollectionViewDelegate,
                                          PreferencesWorkspaceInputViewControllerDelegate {
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var editButton: NSButton!
    
    private let cellId = "BitbucketUserCollectionViewItem"
    private var workspaceDataList = [PreferencesWorkspaceCollectionData]()
    private let authUser = AuthUser.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = NSNib(nibNamed: "TextCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        fetch()
        updateEditButton()
    }
    
    private func fetch() {
        self.workspaceDataList = []
        self.collectionView.reloadData()
        
        guard let user = authUser.currentUser() else { return }
        loadingIndicator.startAnimation(self)
        async({ _ -> [PreferencesRepository.WorkspaceData] in
            return try await(PreferencesRepository.Workspace().index(userId: user.uid))
        }).then({ fetchedWorkspaceDataList in
            self.workspaceDataList = fetchedWorkspaceDataList.map({ (fetchedWorkspaceData) -> PreferencesWorkspaceCollectionData in
                return PreferencesWorkspaceCollectionData(workspaceData: fetchedWorkspaceData, selected: false)
            })
            self.collectionView.reloadData()
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to fetch workspaces. \(error.localizedDescription)").runModal()
        }.always(in: .main) {
            self.loadingIndicator.stopAnimation(self)
        }
    }
    
    private func selectedData() -> PreferencesRepository.WorkspaceData? {
        return workspaceDataList.first(where: { $0.selected })?.workspaceData
    }
    
    private func updateEditButton() {
        editButton.isEnabled = selectedData() != nil
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return workspaceDataList.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! TextCollectionViewItem
        let data = workspaceDataList[indexPath.item]
        item.isSelected = data.selected
        item.setLabelText(labelText: data.workspaceData.name)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        indexPaths.forEach { (indexPath) in
            workspaceDataList[indexPath.item].selected = true
            if let item = collectionView.item(at: indexPath) as? TextCollectionViewItem {
                item.isSelected = true
            }
        }
        updateEditButton()
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        indexPaths.forEach { (indexPath) in
            workspaceDataList[indexPath.item].selected = false
            if let item = collectionView.item(at: indexPath) as? TextCollectionViewItem {
                item.isSelected = false
            }
        }
        updateEditButton()
    }
    
    func willDismiss(vc: PreferencesWorkspaceInputViewController) {
        fetch()
    }
    
    @IBAction func pushAddWorkspace(_ sender: Any) {
        let vc = PreferencesWorkspaceInputViewController.create(workspaceData: nil, delegate: self)
        presentAsSheet(vc)
    }
    
    @IBAction func pushEditButton(_ sender: Any) {
        if let workspaceData = selectedData() {
            let vc = PreferencesWorkspaceInputViewController.create(workspaceData: workspaceData, delegate: self)
            presentAsSheet(vc)
        }
    }
}
