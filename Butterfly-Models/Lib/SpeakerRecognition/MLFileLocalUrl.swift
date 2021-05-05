//
//  MLFileLocalUrl.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/25.
//

import Foundation

class MLFileLocalUrl {
    static func createLocalUrl() -> URL {
        let url = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0]).appendingPathComponent("mlmodel")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }
    
    static func createCompiledModelFileName(modelFileName: String) -> String {
        return "\(modelFileName)c"
    }
}
