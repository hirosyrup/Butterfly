//
//  MainViewController.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/10.
//

import Cocoa
import Hydra

class MainViewController: NSViewController,
                          PreferencesWindowControllerDelegate,
                          MeetingViewControllerDelegate,
                          StatementWindowControllerDelegate,
                          FirestoreWorkspaceNotification {
    @IBOutlet weak var noteLabel: NSTextField!
    @IBOutlet weak var meetingVcContainer: NSView!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    
    private let window = NSWindow()
    private var preferencesWindowController: PreferencesWindowController?
    private var statementWindowController: StatementWindowController?
    private var meetingViewController: MeetingViewController!
    private var userData: WorkspaceRepository.UserData?
    private var isLoadingUserData = false
    
    class func create() -> MainViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("MainViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! MainViewController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirestoreObserver.shared.addWorkspaceObserver(observer: self)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? MeetingViewController {
            vc.delegate = self
            meetingViewController = vc
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        fetchUserData()
        updateViews()
    }
    
    private func fetchUserData() {
        guard userData == nil else { return }
        guard let userId = AuthUser.shared.currentUser()?.uid else { return }
        
        loadingIndicator.startAnimation(self)
        isLoadingUserData = true
        async({ _ -> WorkspaceRepository.UserData? in
            return try await(WorkspaceRepository.User(userId: userId).fetch())
        }).then({ userData in
            self.userData = userData
            self.isLoadingUserData = false
            self.updateViews()
            if userData != nil {
                self.meetingViewController!.setup(userData: userData!)
            }
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to fetch user data. \(error.localizedDescription)").runModal()
        }.always(in: .main) {
            self.loadingIndicator.stopAnimation(self)
        }
    }

    private func updateViews() {
        meetingVcContainer.isHidden = true
        noteLabel.isHidden = true
        
        if isLoadingUserData { return }
        
        if !FirestoreSetup().isConfigured() {
            noteLabel.isHidden = false
            noteLabel.stringValue = "You need to complete the Firebase settings first."
        } else if AuthUser.shared.currentUser() == nil {
            noteLabel.isHidden = false
            noteLabel.stringValue = "You need to sign in."
        } else {
            meetingVcContainer.isHidden = false
        }
    }
    
    private func showStatementWindowController(workspaceId: String, data: MeetingRepository.MeetingData) {
        let wc = StatementWindowController.create(workspaceId: workspaceId, meetingData: data)
        wc.delegate = self
        wc.showWindow(window)
        statementWindowController = wc
        updateIsEntering(isEntering: true, workspaceId: workspaceId, data: data)
    }
    
    private func updateIsEntering(isEntering: Bool, workspaceId: String, data: MeetingRepository.MeetingData) {
        guard let index = data.userList.firstIndex(where: {$0.id == userData?.id}) else { return }
        var updateData = data
        updateData.userList[index].isEntering = isEntering
        async({ _ -> MeetingRepository.MeetingData in
            return try await(MeetingRepository.Meeting().update(workspaceId: workspaceId, meetingData: updateData))
        }).then { (_) in }
    }
    
    func openMeeting(workspaceId: String, meetingId: String) {
        async({ _ -> MeetingRepository.MeetingData? in
            return try await(MeetingRepository.Meeting().fetch(workspaceId: workspaceId, meetingId: meetingId))
        }).then({ meetingData in
            if let data = meetingData {
                self.showStatementWindowController(workspaceId: workspaceId, data: data)
            } else {
                AlertBuilder.createErrorAlert(title: "Error", message: "Not Found the meeting.").runModal()
            }
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to fetch meeting data. \(error.localizedDescription)").runModal()
        }
    }
    
    func willClose(vc: PreferencesWindowController) {
        preferencesWindowController = nil
    }
    
    func willClose(vc: StatementWindowController) {
        updateIsEntering(isEntering: false, workspaceId: vc.workspaceId, data: vc.meetingData)
        statementWindowController = nil
    }
    
    func didChangeWorkspaceData(observer: FirestoreObserver) {
        userData = nil
        fetchUserData()
        updateViews()
    }
    
    func didClickItem(vc: MeetingViewController, workspaceId: String, data: MeetingRepository.MeetingData) {
        showStatementWindowController(workspaceId: workspaceId, data: data)
    }
    
    @IBAction func pushPreferences(_ sender: Any) {
        let wc = PreferencesWindowController.create()
        wc.delegate = self
        wc.showWindow(window)
        preferencesWindowController = wc
    }

    @IBAction func pushQuit(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
}

