//
//  StatementWindowController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa
import Hydra

protocol StatementWindowControllerDelegate: class {
    func willClose(vc: StatementWindowController)
}

class StatementWindowController: NSWindowController, NSWindowDelegate {
    weak var delegate: StatementWindowControllerDelegate?
    private(set) var workspaceId: String!
    weak var statementViewController: StatementViewController?
    
    class func create(workspaceId: String, workspaceMLFileName: String?, meetingData: MeetingRepository.MeetingData) -> StatementWindowController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("StatementWindowController")
        let wc = storyboard.instantiateController(withIdentifier: identifier) as! StatementWindowController
        wc.workspaceId = workspaceId
        wc.setup(workspaceId: workspaceId, workspaceMLFileName: workspaceMLFileName, meetingData: meetingData)
        return wc
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.animationBehavior = .documentWindow
        window?.delegate = self
    }
    
    private func setup(workspaceId: String, workspaceMLFileName: String?, meetingData: MeetingRepository.MeetingData) {
        if let vc = contentViewController as? StatementViewController {
            vc.setup(workspaceId: workspaceId, workspaceMLFileName: workspaceMLFileName, meetingData: meetingData)
            statementViewController = vc
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        delegate?.willClose(vc: self)
    }
}
