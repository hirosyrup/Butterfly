//
//  PreferencesWorkspaceInputViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/17.
//

import Cocoa
import Hydra

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
    
    class func create(workspaceData: PreferencesRepository.WorkspaceData?) -> PreferencesWorkspaceInputViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PreferencesWorkspaceInputViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! PreferencesWorkspaceInputViewController
        vc.workspaceData = workspaceData ?? PreferencesRepository.WorkspaceData(users: [])
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        updateViews()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let selectVc = segue.destinationController as? SelectMemberViewController {
            selectVc.delegate = self
        }
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
    
    func didChangeSelectedUserList(vc: SelectMemberViewController, selectedUserDataList: [PreferencesRepository.UserData]) {
        self.selectedUserDataList = selectedUserDataList
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
            self.dismiss(self)
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to save workspace. \(error.localizedDescription)").runModal()
        }.always(in: .main) {
            self.isProcessing = false
            self.updateViews()
        }
    }
    
    @IBAction func pushCancel(_ sender: Any) {
        dismiss(self)
    }
}
