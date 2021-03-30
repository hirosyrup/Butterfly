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
}
