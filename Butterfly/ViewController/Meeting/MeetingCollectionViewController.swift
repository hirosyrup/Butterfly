//
//  MeetingCollectionViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Cocoa
import Hydra

protocol MeetingCollectionViewControllerDelegate: class {
    func didClickItem(vc: MeetingCollectionViewController, data: MeetingRepository.MeetingData)
}

class MeetingCollectionViewController: NSViewController,
                                       NSCollectionViewDataSource,
                                       NSCollectionViewDelegate,
                                       MeetingCollectionViewItemDelegate {
    @IBOutlet weak var noMeetingLabel: NSTextField!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private let cellId = "MeetingCollectionViewItem"
    private let meetingRepository = MeetingRepository.Meeting()
    var userId = ""
    private var workspaceId = ""
    private var meetingDataList = [MeetingRepository.MeetingData]()
    weak var delegate: MeetingCollectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noMeetingLabel.isHidden = true
        collectionView.isHidden = true
        collectionView.dataSource = self
        collectionView.delegate = self
        let nib = NSNib(nibNamed: "MeetingCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
    }
    
    func update(meetingDataList: [MeetingRepository.MeetingData], workspaceId: String) {
        self.meetingDataList = meetingDataList
        self.workspaceId = workspaceId
        collectionView.reloadData()
        updateViews()
    }
    
    private func updateViews() {
        let isEmpty = meetingDataList.isEmpty
        noMeetingLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
    
    private func archiveMeeting(archiveData: MeetingRepository.MeetingData) {
        async({ _ -> Void in
            try await(self.meetingRepository.archive(workspaceId: self.workspaceId, meetingData: archiveData))
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to delete meeting. \(error.localizedDescription)").runModal()
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return meetingDataList.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! MeetingCollectionViewItem
        let meetingData = meetingDataList[indexPath.item]
        item.updateView(presenter: MeetingCollectionViewItemPresenter(data: meetingData))
        item.delegate = self
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        delegate?.didClickItem(vc: self, data: meetingDataList[indexPath.item])
        collectionView.deselectItems(at: indexPaths)
    }
    
    func didPushEdit(view: MeetingCollectionViewItem) {
        if let indexPath = collectionView.indexPath(for: view) {
            let meetingData = meetingDataList[indexPath.item]
            let vc = MeetingInputViewController.create(workspaceId: workspaceId, hostUserId: userId, meetingData: meetingData)
            presentAsSheet(vc)
        }
    }
    
    func didPushArchive(view: MeetingCollectionViewItem) {
        if let indexPath = collectionView.indexPath(for: view) {
            let archiveData = meetingDataList[indexPath.item]
            let alert = AlertBuilder.createConfirmAlert(title: "Confirmation", message: "Are you sure you want to archive the meeting? The data remains, but is no longer accessible to the application.")
            if alert.runModal() == .alertFirstButtonReturn {
                archiveMeeting(archiveData: archiveData)
            }
        }
    }
}
