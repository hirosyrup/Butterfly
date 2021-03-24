//
//  StatementShareViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/25.
//

import Cocoa

class StatementShareViewController: NSViewController {
    var meetingName = ""
    var dataList = [StatementRepository.StatementData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func createStringsForCsv() -> String {
        let statementStr = dataList.map { "\($0.user.name), \($0.statement)"}.joined(separator: "\n")
        return "name, statement\n\(statementStr)"
    }
    
    @IBAction func pushExportCsv(_ sender: Any) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(meetingName).csv"
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
    
    @IBAction func pushCopyDeepLink(_ sender: Any) {
    }
}
