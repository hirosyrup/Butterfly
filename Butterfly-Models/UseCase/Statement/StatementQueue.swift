//
//  StatementQueue.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import Hydra
import SwiftyBeaver

class StatementQueue {
    private var queue = [StatementQueueData]()
    private var currentUploading: StatementQueueData?
    private var statementList = [(String, StatementRepository.StatementData)]()
    private let repository = StatementRepository.Statement()
    private let workspaceId: String
    private let meetingId: String
    
    init(workspaceId: String, meetingId: String) {
        self.workspaceId = workspaceId
        self.meetingId = meetingId
    }
    
    func addNewStatement(uuid: String, user: MeetingRepository.MeetingUserData) {
        if statementList.contains(where: { (q) -> Bool in
            q.0 == uuid
        }) {
            return
        }
        let statementData = StatementRepository.StatementData(statement: "", user: StatementRepository.StatementUserData(id: user.id,iconName: user.iconName, iconImageUrl: user.iconImageUrl, name: user.name))
        let newData = StatementQueueData(uuid: uuid, statementData: statementData, type: .create)
        statementList.append((uuid, statementData))
        queue.append(newData)
        exec()
    }
    
    func updateStatement(uuid: String, statement: String) {
        if var statementData = statementList.first(where: { $0.0 == uuid })?.1 {
            if statementData.id == "" { return }
            statementData.statement = statement
            let updateData = StatementQueueData(uuid: uuid, statementData: statementData, type: .update)
            if let queueIndex = queue.firstIndex(where: { $0.uuid == uuid }) {
                queue[queueIndex] = updateData
            } else {
                queue.append(updateData)
            }
            exec()
        }
    }
    
    func endStatement(uuid: String, statement: String) {
        if statement.isEmpty {
            deleteStatement(uuid: uuid)
        } else {
            updateStatement(uuid: uuid, statement: statement)
        }
        if let index = statementList.firstIndex(where: { $0.0 == uuid }) {
            statementList.remove(at: index)
        }
    }
    
    private func deleteStatement(uuid: String) {
        if let statementData = statementList.first(where: { $0.0 == uuid })?.1 {
            if statementData.id == "" { return }
            let deleteData = StatementQueueData(uuid: uuid, statementData: statementData, type: .delete)
            if let queueIndex = queue.firstIndex(where: { $0.uuid == uuid }) {
                queue[queueIndex] = deleteData
            } else {
                queue.append(deleteData)
            }
            exec()
        }
    }
    
    private func exec() {
        guard currentUploading == nil else { return }
        guard !queue.isEmpty else { return }
        currentUploading = queue[0]
        queue.remove(at: 0)
        switch currentUploading!.type {
        case .create:
            create(uuid: currentUploading!.uuid, statementData: currentUploading!.statementData)
        case .update:
            update(uuid: currentUploading!.uuid, statementData: currentUploading!.statementData)
        case .delete:
            delete(uuid: currentUploading!.uuid, statementData: currentUploading!.statementData)
        }
    }
    
    private func updateStatementData(uuid: String, statementData: StatementRepository.StatementData) {
        if let index = statementList.firstIndex(where: { $0.0 == uuid }) {
            statementList[index] = (uuid, statementData)
        }
    }
    
    private func create(uuid: String, statementData: StatementRepository.StatementData) {
        async({ _ -> StatementRepository.StatementData in
            return try await(self.repository.create(workspaceId: self.workspaceId, meetingId: self.meetingId, statementData: statementData))
        }).then({newStatementData in
            self.updateStatementData(uuid: uuid, statementData: newStatementData)
            self.finish()
            self.exec()
        }).catch { (error) in
            SwiftyBeaver.self.error(error)
            self.remandToQueue()
            self.exec()
        }
    }
    
    private func update(uuid: String, statementData: StatementRepository.StatementData) {
        async({ _ -> StatementRepository.StatementData in
            return try await(self.repository.update(workspaceId: self.workspaceId, meetingId: self.meetingId, statementData: statementData))
        }).then({newStatementData in
            self.updateStatementData(uuid: uuid, statementData: newStatementData)
            self.finish()
            self.exec()
        }).catch { (error) in
            SwiftyBeaver.self.error(error)
            self.remandToQueue()
            self.exec()
        }
    }
    
    private func delete(uuid: String, statementData: StatementRepository.StatementData) {
        async({ _ -> Void in
            try await(self.repository.delete(workspaceId: self.workspaceId, meetingId: self.meetingId, statementId: statementData.id))
        }).then({_ in
            self.finish()
            self.exec()
        }).catch { (error) in
            SwiftyBeaver.self.error(error)
            self.remandToQueue()
            self.exec()
        }
    }
    
    private func finish() {
        currentUploading = nil
    }
    
    private func remandToQueue() {
        guard let _currentUploading = currentUploading else { return }
        queue.insert(_currentUploading, at: 0)
        currentUploading = nil
    }
}
