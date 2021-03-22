//
//  StatementViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class StatementViewController: NSViewController {
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var memberIconContainer: MemberIconContainer!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var workspaceId: String!
    private var meetingData: MeetingRepository.MeetingData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setup(workspaceId: String, meetingData: MeetingRepository.MeetingData) {
        self.workspaceId = workspaceId
        self.meetingData = meetingData
        titleLabel.stringValue = meetingData.name
        memberIconContainer.updateView(imageUrls: meetingData.userList.map { $0.iconImageUrl })
    }
}
