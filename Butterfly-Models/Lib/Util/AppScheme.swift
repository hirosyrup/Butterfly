//
//  AppScheme.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/25.
//

import Foundation

class AppScheme {
    private let schemeName = "Butterfly:"
    let openMeetingPath = "open-meeting"
    let openMeetingPathWorkspaceIdKey = "workspace-id"
    let openMeetingPathMeetingIdKey = "meeting-id"
    
    func openMeetingScheme(workspaceId: String, meetingId: String) -> String {
        return "\(schemeName)\(openMeetingPath)?\(openMeetingPathWorkspaceIdKey)=\(workspaceId)&\(openMeetingPathMeetingIdKey)=\(meetingId)"
    }
}
