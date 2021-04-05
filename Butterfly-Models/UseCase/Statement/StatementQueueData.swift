//
//  StatementQueueData.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation

struct StatementQueueData {
    let uuid: String
    var statementData: StatementRepository.StatementData
    let type: StatementQueueType
}
