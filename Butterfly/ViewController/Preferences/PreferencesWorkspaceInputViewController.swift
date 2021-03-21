//
//  PreferencesWorkspaceInputViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/17.
//

import Cocoa
import Hydra

protocol PreferencesWorkspaceInputViewControllerDelegate: class {
    func willDismiss(vc: PreferencesWorkspaceInputViewController)
}

class PreferencesWorkspaceInputViewController: NSViewController,
                                               NSTextFieldDelegate,
                                               SelectMemberViewControllerDelegate {
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var memberSelectContainer: NSView!
    @IBOutlet weak var cancelButton: NSButton!
    fileprivate var workspaceData: PreferencesRepository.WorkspaceData!
    private var isProcessing = false
    private var selectedUserDataList = [PreferencesRepository.UserData]()
    
    fileprivate weak var delegate: PreferencesWorkspaceInputViewControllerDelegate?
    
    class func create(workspaceData: PreferencesRepository.WorkspaceData?, delegate: PreferencesWorkspaceInputViewControllerDelegate? = nil) -> PreferencesWorkspaceInputViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PreferencesWorkspaceInputViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! PreferencesWorkspaceInputViewController
        vc.workspaceData = workspaceData ?? PreferencesRepository.WorkspaceData(users: [])
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
            selectVc.setup(selectMemberFetch: SelectMemberFetchForPreferences(), userList: createInitialSelectedUserList(), delegate: self)
        }
    }
    
    private func setup() {
        nameTextField.stringValue = workspaceData.name
    }
    
    private func createInitialSelectedUserList() -> [SelectMemberUserData] {
        return workspaceData.users.map { SelectMemberUserData(id: $0.id, iconImageUrl: $0.iconImageUrl, name: $0.name) }
    }
    
    private func updateViews() {
        if isProcessing  {
            okButton.isEnabled = false
            cancelButton.isEnabled = false
            nameTextField.isEnabled = false
        } else {
            okButton.isEnabled = !self.selectedUserDataList.isEmpty && !nameTextField.stringValue.isEmpty
            cancelButton.isEnabled = true
            nameTextField.isEnabled = true
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateViews()
    }
    
    func didChangeSelectedUserList(vc: SelectMemberViewController, selectedIndices: [Int]) {
        let fetch = vc.selectMemberFetch as! SelectMemberFetchForPreferences
        self.selectedUserDataList = fetch.originalUserDataListAt(selectedIndices)
        self.updateViews()
    }
    
    @IBAction func pushOk(_ sender: Any) {
        isProcessing = true
        updateViews()
        var newWorkspaceData = workspaceData!
        newWorkspaceData.name = nameTextField.stringValue
        newWorkspaceData.users = selectedUserDataList
        async({ _ -> PreferencesRepository.WorkspaceData in
            return try await(SaveWorkspace(data: newWorkspaceData).save())
        }).then({ savedWorkspaceData in
            self.delegate?.willDismiss(vc: self)
            self.dismiss(self)
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to save workspace. \(error.localizedDescription)").runModal()
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
