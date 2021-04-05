//
//  StatementRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation
import Hydra
import SwiftyBeaver

protocol StatementRepositoryDelegate: class {
    func didChangeStatementData(obj: StatementRepository.Statement, documentChanges: [RepositoryDocumentChange<StatementRepository.StatementData>])
}

class StatementRepository {
    struct StatementData {
        fileprivate let original: FirestoreStatementData
        let id: String
        var statement: String
        var user: StatementUserData
        let createdAt: Date
        
        init(statement: String, user: StatementUserData) {
            self.id = ""
            self.statement = statement
            self.user = user
            self.original = FirestoreStatementData.new()
            self.createdAt = self.original.createdAt
        }
        
        init(user: StatementUserData, original: FirestoreStatementData? = nil) {
            self.user = user
            self.original = original ?? FirestoreStatementData.new()
            self.id = self.original.id
            self.statement = self.original.statement
            self.createdAt = self.original.createdAt
        }
        
        fileprivate func toFirestoreData() -> FirestoreStatementData {
            var firestoreData = original
            firestoreData.statement = statement
            firestoreData.user = user.toFirestoreData()
            return firestoreData
        }
    }
    
    struct StatementUserData {
        let id: String
        let iconName: String?
        let iconImageUrl: URL?
        let name: String
        
        init(id: String, iconName: String?, iconImageUrl: URL?, name: String) {
            self.id = id
            self.iconName = iconName
            self.iconImageUrl = iconImageUrl
            self.name = name
        }
        
        init(iconImageUrl: URL?, firestoreData: FirestoreStatementUserData) {
            self.iconImageUrl = iconImageUrl
            self.id = firestoreData.id
            self.iconName = firestoreData.iconName
            self.name = firestoreData.name
        }
        
        fileprivate func toFirestoreData() -> FirestoreStatementUserData {
            FirestoreStatementUserData(id: id, iconName: iconName, name: name)
        }
    }
    
    class Statement: FirestoreStatementDelegate {
        private let statement = FirestoreStatement()
        private let iconImage = IconImage.shared
        weak var delegate: StatementRepositoryDelegate?
        
        init() {
            statement.delegate = self
        }
        
        func listen(workspaceId: String, meetingId: String) {
            statement.listen(workspaceId: workspaceId, meetingId: meetingId)
        }
        
        func unlisten() {
            statement.unlisten()
        }
        
        func create(workspaceId: String, meetingId: String, statementData: StatementData) -> Promise<StatementData> {
            return Promise<StatementData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> StatementData in
                    let createdFirestoreStatementData = try await(self.statement.add(workspaceId: workspaceId, meetingId: meetingId, data: statementData.toFirestoreData()))
                    return try await(self.createStatementData(firestoreStatementData: createdFirestoreStatementData))
                }).then({ statementData in
                    resolve(statementData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func update(workspaceId: String, meetingId: String, statementData: StatementData) -> Promise<StatementData> {
            return Promise<StatementData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> StatementData in
                    let statementId = statementData.original.id
                    let firestoreStatementData = statementData.toFirestoreData().copyCurrentAt()
                    let savedFirestoreStatementData = try await(self.statement.update(workspaceId: workspaceId, meetingId: meetingId, statementId: statementId, data: firestoreStatementData))
                    return try await(self.createStatementData(firestoreStatementData: savedFirestoreStatementData))
                }).then({newStatementData in
                    resolve(newStatementData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func delete(workspaceId: String, meetingId: String, statementId: String) -> Promise<Void> {
            return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> Void in
                    try await(self.statement.delete(workspaceId: workspaceId, meetingId: meetingId, statementId: statementId))
                }).then({_ in
                    resolve(())
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        private func createStatementData(firestoreStatementData: FirestoreStatementData) -> Promise<StatementData> {
            return Promise<StatementData>(in: .background, token: nil) { (resolve, reject, _) in
                async({ _ -> StatementData in
                    let user = firestoreStatementData.user
                    var iconUrl: URL?
                    if let iconName = user.iconName {
                        iconUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                    }
                    let statementUserData = StatementUserData(iconImageUrl: iconUrl, firestoreData: user)
                    
                    return StatementData(user: statementUserData, original: firestoreStatementData)
                }).then({newStatementData in
                    resolve(newStatementData)
                }).catch { (error) in
                    reject(error)
                }
            }
        }
        
        func didChangeStatementData(obj: FirestoreStatement, documentChanges: [FirestoreDocumentChangeWithData<FirestoreStatementData>]) {
            if let _delegate = delegate {
                async({ _ -> [RepositoryDocumentChange<StatementData>] in
                    return try documentChanges.map { (documentChange) -> RepositoryDocumentChange<StatementData> in
                        let statementData = try await(self.createStatementData(firestoreStatementData: documentChange.firestoreData))
                        return RepositoryDocumentChange<StatementData>(documentChange: documentChange.documentChange, data: statementData)
                    }
                }).then({ changes in
                    _delegate.didChangeStatementData(obj: self, documentChanges: changes)
                }).catch { (error) in
                    SwiftyBeaver.self.error(error)
                }
            }
        }
    }
}
