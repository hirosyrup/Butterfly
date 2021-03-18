//
//  PreferencesWorkspaceViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/17.
//

import Cocoa

class PreferencesWorkspaceViewController: NSViewController {
    @IBAction func pushAddWorkspace(_ sender: Any) {
        let vc = PreferencesWorkspaceInputViewController.create()
        presentAsSheet(vc)
    }
}
