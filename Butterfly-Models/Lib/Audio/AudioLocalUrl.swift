//
//  AudioLocalUrl.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/30.
//

import Foundation

class AudioLocalUrl {
    static func createLocalUrl() -> URL {
        return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0])
    }
    
    static func createRecordDirectoryUrl() -> URL {
        let url = createLocalUrl().appendingPathComponent("record")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }
}
