//
//  MainViewController.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/10.
//

import Cocoa
import Hydra

class MainViewController: NSViewController, PreferencesWindowControllerDelegate {
    @IBOutlet weak var noteLabel: NSTextField!
    @IBOutlet weak var meetingVcContainer: NSView!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    
    private let window = NSWindow()
    private var preferencesWindowController: PreferencesWindowController?
    private var meetingViewController: MeetingViewController!
    private var userData: MeetingRepository.UserData?
    private var isLoadingUserData = false
    
    class func create() -> MainViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("MainViewController")
        let vc = storyboard.instantiateController(withIdentifier: identifier) as! MainViewController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let vc = segue.destinationController as? MeetingViewController {
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
        async({ _ -> MeetingRepository.UserData in
            return try await(MeetingRepository.User(userId: userId).fetch())
        }).then({ userData in
            self.userData = userData
            self.isLoadingUserData = false
            self.updateViews()
            self.meetingViewController!.setup(userData: userData)
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
    
    func willClose(vc: PreferencesWindowController) {
        preferencesWindowController = nil
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

