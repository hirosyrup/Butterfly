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
    private var meetingViewController: MeetingViewController?
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
    
    override func viewWillAppear() {
        super.viewWillAppear()
        fetchUserData()
        updateViews()
    }
    
    private func setupMeetingViewController() {
        guard FirestoreSetup().isConfigured() else { return }
        guard meetingViewController == nil else { return }
        meetingViewController = MeetingViewController.create(delegate: self)
        meetingVcContainer.addSubview(meetingViewController!.view)
    }
    
    private func fetchUserData() {
        guard userData == nil else { return }
        guard let userId = AuthUser.shared.currentUser()?.uid else { return }
        
        loadingIndicator.startAnimation(self)
        isLoadingUserData = true
        async({ _ -> WorkspaceRepository.UserData? in
            let userData = try await(WorkspaceRepository.User(userId: userId).fetch())
            if let workspaceList = userData?.workspaceList{
                try workspaceList.forEach { (workspace) in
                    if let mlFileName = workspace.mlFileName {
                        try await(DownloadMLFile(fileName: mlFileName).download())
                    }
                }
            }
            return userData
        }).then({ userData in
            self.userData = userData
            self.isLoadingUserData = false
            self.updateViews()
            if userData != nil {
                self.setupMeetingViewController()
                self.meetingViewController?.setup(userData: userData!)
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
    
    private func showStatementWindowController(workspaceId: String, workspaceMLFileName: String?, data: MeetingRepository.MeetingData) {
        let wc = StatementWindowController.create(workspaceId: workspaceId, workspaceMLFileName: workspaceMLFileName, meetingData: data)
        wc.delegate = self
        wc.showWindow(window)
        statementWindowController = wc
    }
    
    func openMeeting(workspaceId: String, meetingId: String) {
        async({ _ -> (WorkspaceRepository.WorkspaceData?, MeetingRepository.MeetingData?) in
            let workspaceData = try await(WorkspaceRepository.Workspace(workspaceId: workspaceId).fetch())
            return (workspaceData, try await(MeetingRepository.Meeting().fetch(workspaceId: workspaceId, meetingId: meetingId)))
        }).then({ dataTuple in
            if let workspaceData = dataTuple.0, let meetingData = dataTuple.1 {
                let mlFileName = workspaceData.isEnableSpeakerRecognition ? workspaceData.mlFileName : nil
                self.showStatementWindowController(workspaceId: workspaceId, workspaceMLFileName: mlFileName, data: meetingData)
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
        statementWindowController = nil
    }
    
    func didChangeWorkspaceData(observer: FirestoreObserver) {
        userData = nil
        fetchUserData()
        updateViews()
    }
    
    func didClickItem(vc: MeetingViewController, workspaceId: String, workspaceMLFileName: String?, data: MeetingRepository.MeetingData) {
        showStatementWindowController(workspaceId: workspaceId, workspaceMLFileName: workspaceMLFileName, data: data)
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

