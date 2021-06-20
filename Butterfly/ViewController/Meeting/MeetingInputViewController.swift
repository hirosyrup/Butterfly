//
//  MeetingInputViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Cocoa
import Hydra

protocol MeetingInputViewControllerDelegate: class {
    func willDismiss(vc: MeetingInputViewController)
}

class MeetingInputViewController: NSViewController,
                                  NSTextFieldDelegate,
                                  SelectMemberViewControllerDelegate {
    @IBOutlet weak var submitButton: NSButton!
    @IBOutlet weak var nameTextField: EditableNSTextField!
    @IBOutlet weak var memberSelectContainer: NSView!
    @IBOutlet weak var cancelButton: NSButton!
    fileprivate var workspaceId: String!
    fileprivate var hostUserId: String!
    fileprivate var meetingData: MeetingRepository.MeetingData!
    private var isProcessing = false
    private var selectedUserDataList = [MeetingRepository.MeetingIconData]()
    
    fileprivate weak var delegate: MeetingInputViewControllerDelegate?
    
    class func create(workspaceId: String, hostUserId: String, meetingData: MeetingRepository.MeetingData?, delegate: MeetingInputViewControllerDelegate? = nil) -> MeetingInputViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("MeetingInputViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! MeetingInputViewController
        vc.workspaceId = workspaceId
        vc.hostUserId = hostUserId
        vc.meetingData = meetingData ?? MeetingRepository.MeetingData(iconList: [])
        vc.delegate = delegate
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        setup()
        updateViews()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let selectVc = segue.destinationController as? SelectMemberViewController {
            selectVc.setup(selectMemberFetch: SelectMemberFetchForMeeting(workspaceId: workspaceId, meetingData: meetingData), userList: createInitialSelectedUserList(), isSelectable: !meetingData.isFinished(), delegate: self)
        }
    }
    
    private func setup() {
        nameTextField.stringValue = meetingData.name
    }
    
    private func createInitialSelectedUserList() -> [SelectMemberUserData] {
        return meetingData.iconList.map { SelectMemberUserData(id: $0.userId, iconImageUrl: $0.iconImageUrl, name: $0.name) }
    }
    
    private func updateViews() {
        if isProcessing  {
            submitButton.isEnabled = false
            cancelButton.isEnabled = false
            nameTextField.isEnabled = false
        } else {
            submitButton.isEnabled = !self.selectedUserDataList.isEmpty && !nameTextField.stringValue.isEmpty
            cancelButton.isEnabled = true
            nameTextField.isEnabled = true
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateViews()
    }
    
    func didChangeSelectedUserList(vc: SelectMemberViewController, selectedIndices: [Int]) {
        let fetch = vc.selectMemberFetch as! SelectMemberFetchForMeeting
        self.selectedUserDataList = fetch.originalUserDataListAt(selectedIndices)
        self.updateViews()
    }
    
    @IBAction func pushSubmit(_ sender: Any) {
        isProcessing = true
        updateViews()
        var newMeetingData = meetingData!
        newMeetingData.name = nameTextField.stringValue
        newMeetingData.iconList = selectedUserDataList
        async({ _ -> MeetingRepository.MeetingData in
            return try await(SaveMeeting(workspaceId: self.workspaceId, data: newMeetingData).save())
        }).then({ savedMeetingData in
            self.delegate?.willDismiss(vc: self)
            self.dismiss(self)
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to save meeting. \(error.localizedDescription)").runModal()
        }.always(in: .main) {
            self.isProcessing = false
            self.updateViews()
        }
    }
    
    @IBAction func pushCancel(_ sender: Any) {
        delegate?.willDismiss(vc: self)
        dismiss(self)
    }
}
