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
    
    var data: StatementShareViewControllerData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
    }
    
    private func updateView() {
        exportAudioButton.isEnabled = data.audioComposition != nil
    }
    
    private func createStringsForCsv() -> String {
        let statementStr = data.statementDataList.map { "\($0.user?.name ?? DefaultUserName.name), \($0.statement.replacingOccurrences(of: "\n", with: ""))"}.joined(separator: "\n")
        return "name, statement\n\(statementStr)"
    }
    
    @IBAction func pushExportCsv(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(data.meetingData.name).csv"
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
        guard let composition = data.audioComposition else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(data.meetingData.name).m4a"
        savePanel.begin { (response) in
            if response == .OK {
                guard let url = savePanel.url else { return }
                async({ _ -> Void in
                    try await(AudioExport(composition: composition, outputUrl: url).export())
                }).then { (_) in }
            }
        }
    }
    
    @IBAction func pushCopyToClipboard(_ sender: Any) {
        var previousUserId: String? = nil
        let statements = data.statementDataList.map { (data) -> String in
            var statement = ""
            if previousUserId != data.user?.id {
                previousUserId = data.user?.id
                statement += "[\(data.user?.name ?? DefaultUserName.name)]\n"
            }
            return statement + "\(data.statement.replacingOccurrences(of: "\n", with: ""))"
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(statements.joined(separator: "\n\n"), forType: .string)
        dismiss(self)
    }
    
    @IBAction func pushCopyDeepLink(_ sender: Any) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(AppScheme().openMeetingScheme(workspaceId: workspaceId, meetingId: data.meetingData.id), forType: .string)
        dismiss(self)
    }
}
