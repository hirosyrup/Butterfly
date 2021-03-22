//
//  MeetingCollectionViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Cocoa

protocol MeetingCollectionViewControllerDelegate: class {
    func didClickItem(vc: MeetingCollectionViewController, data: MeetingRepository.MeetingData)
}

class MeetingCollectionViewController: NSViewController,
                                       NSCollectionViewDataSource,
                                       NSCollectionViewDelegate,
                                       MeetingRepositoryDelegate {
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var noMeetingLabel: NSTextField!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private let cellId = "MeetingCollectionViewItem"
    private let meetingRepository = MeetingRepository.Meeting()
    private var meetingDataList = [MeetingRepository.MeetingData]()
    weak var delegate: MeetingCollectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noMeetingLabel.isHidden = true
        collectionView.isHidden = true
        meetingRepository.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        let nib = NSNib(nibNamed: "MeetingCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
    }
    
    func changeWorkspaceId(workspaceId: String) {
        meetingDataList = []
        loadingIndicator.startAnimation(self)
        meetingRepository.unlisten()
        meetingRepository.listen(workspaceId: workspaceId)
    }
    
    private func updateViews() {
        let isEmpty = meetingDataList.isEmpty
        noMeetingLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
    
    func didChangeMeetingData(obj: MeetingRepository.Meeting, documentChanges: [RepositoryDocumentChange<MeetingRepository.MeetingData>]) {
        let modifieds = documentChanges.filter { $0.type == .modified }
        modifieds.forEach { (modified) in
            if  self.meetingDataList.count > modified.oldIndex {
                self.meetingDataList[modified.oldIndex] = modified.data
            }
        }
        
        let removesIndex = documentChanges.filter { $0.type == .removed }.map { $0.oldIndex }
        var removedMeetingList = [MeetingRepository.MeetingData]()
        for (index, value) in meetingDataList.enumerated() {
            if !removesIndex.contains(index) {
                removedMeetingList.append(value)
            }
        }
        meetingDataList = removedMeetingList
        
        let addeds = documentChanges.filter { $0.type == .added }
        addeds.forEach { (addedChange) in
            meetingDataList.insert(addedChange.data, at: addedChange.newIndex)
        }
        
        loadingIndicator.stopAnimation(self)
        collectionView.reloadData()
        updateViews()
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return meetingDataList.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! MeetingCollectionViewItem
        let meetingData = meetingDataList[indexPath.item]
        item.updateView(presenter: MeetingCollectionViewItemPresenter(data: meetingData))
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        delegate?.didClickItem(vc: self, data: meetingDataList[indexPath.item])
        collectionView.deselectItems(at: indexPaths)
    }
}
