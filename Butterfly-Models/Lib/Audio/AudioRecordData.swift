//
//  AudioRecordData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/29.
//

import Foundation

struct AudioRecordData {
    let fileName: String
    let startTime: Float
    let endTime: Float
    let meetingId: String
    
    static func createFromUserDefaultData(data: [String: String]) -> AudioRecordData {
        let startTime = data["startTime"] ?? "0.0"
        let endTime = data["endTime"] ?? "0.0"
        return AudioRecordData(
            fileName: data["fileName"] ?? "",
            startTime: Float(startTime)!,
            endTime: Float(endTime)!,
            meetingId: data["meetingId"] ?? ""
        )
    }
    
    func createToUserDefaultData() -> [String: String] {
        return [
            "fileName": fileName,
            "startTime": String(startTime),
            "endTime": String(endTime),
            "meetingId": meetingId
        ]
    }
}
