//
//  StatementShareViewControllerData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/06.
//

import Foundation
import AVFoundation

struct StatementShareViewControllerData {
    let workspaceId: String
    let meetingData: MeetingRepository.MeetingData
    let statementDataList: [StatementRepository.StatementData]
    let audioComposition: AVMutableComposition?
}
