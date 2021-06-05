//
//  StatementOptionUserDefault.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/06/05.
//

import Foundation

class StatementOptionUserDefault {
    static let shared = StatementOptionUserDefault()
    
    let userDefault = UserDefaults.standard
    
    private let mutingSilentPartKey = "mutingSilentPart"
    private let autoScrollKey = "autoScroll"
    
    init() {
        userDefault.register(defaults: [
            mutingSilentPartKey: true,
            autoScrollKey: true
        ])
    }
    
    func saveMutingSilentPart(isMutingSilentPart: Bool) {
        userDefault.setValue(isMutingSilentPart, forKey: mutingSilentPartKey)
    }
    
    func saveAutoScroll(isAutoScroll: Bool) {
        userDefault.setValue(isAutoScroll, forKey: autoScrollKey)
    }
    
    func isMutingSilentPart() -> Bool {
        userDefault.bool(forKey: mutingSilentPartKey)
    }
    
    func isAutoScroll() -> Bool {
        userDefault.bool(forKey: autoScrollKey)
    }
}
