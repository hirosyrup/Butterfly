//
//  VoiceprintPadding.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/12.
//

import Foundation

class VoiceprintPadding {
    private let type: VoiceprintPaddingType
    private let originalFileUrl: URL
    
    init(type: VoiceprintPaddingType, originalFileUrl: URL) {
        self.type = type
        self.originalFileUrl = originalFileUrl
    }
}
