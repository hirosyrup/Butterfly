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
    @IBOutlet weak var enableSpeakerRecognitionSwitch: NSSwitch!
    @IBOutlet weak var uploadMLFileButton: NSButton!
    @IBOutlet weak var MLFileNameLabel: NSTextField!
    @IBOutlet weak var MLFileUploadViewContainer: NSView!
    @IBOutlet weak var saveIndicator: NSProgressIndicator!
    
    fileprivate var workspaceData: PreferencesRepository.WorkspaceData!
    private var isProcessing = false
    private var selectedUserDataList = [PreferencesRepository.UserData]()
    private var selectedUploadMLFileUrl: URL?
    
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
        selectedUserDataList = workspaceData.users
        enableSpeakerRecognitionSwitch.state = workspaceData.isEnableSpeakerRecognition ? .on : .off
        if let mlFileName = workspaceData.mlFileName {
            let fileUrl = MLFileLocalUrl.createLocalUrl().appendingPathComponent(mlFileName)
            if FileManager.default.fileExists(atPath: fileUrl.path) {
                selectedUploadMLFileUrl = fileUrl
            }
        }
    }
    
    private func createInitialSelectedUserList() -> [SelectMemberUserData] {
        return workspaceData.users.map { SelectMemberUserData(id: $0.id, iconImageUrl: $0.iconImageUrl, name: $0.name) }
    }
    
    private func updateViews() {
        if isProcessing  {
            okButton.isEnabled = false
            cancelButton.isEnabled = false
            nameTextField.isEnabled = false
            enableSpeakerRecognitionSwitch.isEnabled = false
            uploadMLFileButton.isEnabled = false
        } else {
            okButton.isEnabled = !self.selectedUserDataList.isEmpty && !nameTextField.stringValue.isEmpty && !(enableSpeakerRecognitionSwitch.state == .on && selectedUploadMLFileUrl == nil)
            cancelButton.isEnabled = true
            nameTextField.isEnabled = true
            enableSpeakerRecognitionSwitch.isEnabled = true
            uploadMLFileButton.isEnabled = true
        }
        
        MLFileUploadViewContainer.isHidden = enableSpeakerRecognitionSwitch.state != .on
        MLFileNameLabel.stringValue = selectedUploadMLFileUrl?.lastPathComponent ?? ""
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
        saveIndicator.startAnimation(true)
        updateViews()
        var newWorkspaceData = workspaceData!
        newWorkspaceData.name = nameTextField.stringValue
        newWorkspaceData.users = selectedUserDataList
        newWorkspaceData.isEnableSpeakerRecognition = enableSpeakerRecognitionSwitch.state == .on
        async({ _ -> PreferencesRepository.WorkspaceData in
            return try await(SaveWorkspace(data: newWorkspaceData, MLFileUrl: self.selectedUploadMLFileUrl).save())
        }).then({ savedWorkspaceData in
            self.delegate?.willDismiss(vc: self)
            self.dismiss(self)
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to save workspace. \(error.localizedDescription)").runModal()
        }.always(in: .main) {
            self.isProcessing = false
            self.saveIndicator.startAnimation(true)
            self.updateViews()
        }
    }
    
    @IBAction func pushCancel(_ sender: Any) {
        delegate?.willDismiss(vc: self)
        dismiss(self)
    }
    
    @IBAction func changeEnableSpeakerRecognitionSwitch(_ sender: Any) {
        updateViews()
    }
    
    @IBAction func pushUploadMLFileButton(_ sender: Any) {
        guard let window = NSApp.keyWindow else { return }
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select a mlmodel file."
        openPanel.allowedFileTypes = ["mlmodel"]
        openPanel.beginSheetModal(for: window, completionHandler: { (response) in
            if response == .OK {
                if let url = openPanel.url {
                    self.selectedUploadMLFileUrl = url
                    self.updateViews()
                }
            }
        })
    }
}
