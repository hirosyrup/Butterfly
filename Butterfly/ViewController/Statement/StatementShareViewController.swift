//
//  StatementShareViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/25.
//

import Cocoa
import AVFoundation
import Hydra

class StatementShareViewController: NSViewController {
    @IBOutlet weak var exportAudioButton: NSButton!
    
    var workspaceId: String = ""
    var meetingData: MeetingRepository.MeetingData!
    var dataList = [StatementRepository.StatementData]()
    var audioComposition: AVMutableComposition?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
    }
    
    private func updateView() {
        exportAudioButton.isEnabled = audioComposition != nil
    }
    
    private func createStringsForCsv() -> String {
        let statementStr = dataList.map { "\($0.user.name), \($0.statement)"}.joined(separator: "\n")
        return "name, statement\n\(statementStr)"
    }
    
    @IBAction func pushExportCsv(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(meetingData.name).csv"
        savePanel.begin { (response) in
            if response == .OK {
                guard let url = savePanel.url else { return }
                do {
                    try self.createStringsForCsv().write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    AlertBuilder.createErrorAlert(title: "Error", message: "Failed to export CSV. \(error.localizedDescription)").runModal()
                }
            }
        }
    }
    
    @IBAction func pushExportAudio(_ sender: Any) {
        guard let composition = audioComposition else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(meetingData.name).m4a"
        savePanel.begin { (response) in
            if response == .OK {
                guard let url = savePanel.url else { return }
                async({ _ -> Void in
                    try await(AudioExport(composition: composition, outputUrl: url).export())
                }).then { (_) in }
            }
        }
    }
    
    @IBAction func pushCopyDeepLink(_ sender: Any) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(AppScheme().openMeetingScheme(workspaceId: workspaceId, meetingId: meetingData.id), forType: .string)
        dismiss(self)
    }
}
