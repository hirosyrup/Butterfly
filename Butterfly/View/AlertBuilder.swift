//
//  AlertBuilder.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/14.
//

import Cocoa

class AlertBuilder {
    static func createErrorAlert(title: String, message: String) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        return alert
    }
    
    static func createCompletionAlert(title: String, message: String) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        return alert
    }
    
    static func createConfirmAlert(title: String, message: String) -> NSAlert {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return alert
    }
}
