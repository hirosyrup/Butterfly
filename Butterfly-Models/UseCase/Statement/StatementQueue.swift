//
//  StatementQueue.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import Hydra

class StatementQueue {
    private var queue = [StatementQueueData]()
    private let repository = StatementRepository.Statement()
    private let workspaceId: String
    private let meetingId: String
    
    init(workspaceId: String, meetingId: String) {
        self.workspaceId = workspaceId
        self.meetingId = meetingId
    }
    
    func addNewStatement(statementId: String, user: MeetingRepository.MeetingUserData) {
        if queue.contains(where: { (q) -> Bool in
            q.statementId == statementId
        }) {
            return
        }
        
        queue.append(StatementQueueData(statementId: statementId, satementData: nil))
        async({ _ -> StatementRepository.StatementData in
            let data = StatementRepository.StatementData(statement: "", user: StatementRepository.StatementUserData(iconName: user.iconName, iconImageUrl: user.iconImageUrl, name: user.name))
            return try await(self.repository.create(workspaceId: self.workspaceId, meetingId: self.meetingId, statementData: data))
        }).then({newStatementData in
            self.updateQueue(statementId: statementId, statementData: newStatementData)
        }).catch { (error) in
            print("\(error)")
        }
    }
    
    func updateStatement(statementId: String, statement: String) {
        if let index = queue.firstIndex(where: { $0.statementId == statementId }) {
            guard var statementData = queue[index].satementData else { return }
            statementData.statement = statement
            async({ _ -> StatementRepository.StatementData in
                return try await(self.repository.update(workspaceId: self.workspaceId, meetingId: self.meetingId, statementData: statementData))
            }).then({newStatementData in
                self.updateQueue(statementId: statementId, statementData: newStatementData)
            }).catch { (error) in
                print("\(error)")
            }
        }
    }
    
    func endStatement(statementId: String, statement: String) {
        updateStatement(statementId: statementId, statement: statement)
        if let index = queue.firstIndex(where: { $0.statementId == statementId }) {
            queue.remove(at: index)
        }
    }
    
    private func updateQueue(statementId: String, statementData: StatementRepository.StatementData) {
        if let index = queue.firstIndex(where: { $0.statementId == statementId }) {
            queue[index].satementData = statementData
        }
    }
}
