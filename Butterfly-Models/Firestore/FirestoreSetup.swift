//
//  FirestoreSetup.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/11.
//

import Foundation
import Firebase

class FirestoreSetup {
    private let url: URL?
    
    init() {
        self.url = SettingUserDefault().firebasePlistUrl()
    }
    
    func setup() {
        guard let path = url?.path.removingPercentEncoding else { return }
        if let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(options: options)
        }
    }
}
