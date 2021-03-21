//
//  MeetingCollectionViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Cocoa

class MeetingCollectionViewController: NSViewController,
                                       MeetingRepositoryDelegate {
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    @IBOutlet weak var noMeetingLabel: NSTextField!
    @IBOutlet weak var collectionView: NSScrollView!
    
    private let meetingRepository = MeetingRepository.Meeting()
    private var meetingDataList = [MeetingRepository.MeetingData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noMeetingLabel.isHidden = true
        collectionView.isHidden = true
        meetingRepository.delegate = self
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
        updateViews()
    }
}
