//
//  PreferencesViewController.swift
//  Butterfly-iOS
//
//  Created by 岩井 宏晃 on 2021/05/31.
//

import UIKit

class PreferencesViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func pushCloseButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
