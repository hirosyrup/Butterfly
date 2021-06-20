//
//  StatementCollectionDataProvider.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/05/07.
//

import Foundation

protocol StatementCollectionDataProviderDelegate: class {
    func didUpdateDataList(provider: StatementCollectionDataProvider)
}

class StatementCollectionDataProvider: StatementRepositoryDelegate {
    weak var delegate: StatementCollectionDataProviderDelegate?
    
    private let statement = StatementRepository.Statement()
    private(set) var statementDataList = [StatementRepository.StatementData]()
    private let workspaceId: String
    private let meetingId: String
    private(set) var filterHitIndices = [Int]()
    
    init(workspaceId: String, meetingId: String) {
        self.workspaceId = workspaceId
        self.meetingId = meetingId
    }
    
    func listenData() {
        statement.listen(workspaceId: workspaceId, meetingId: meetingId)
        statement.delegate = self
    }
    
    func unlistenData() {
        statement.unlisten()
    }
    
    func updateFilterHitIndices(keyword: String) {
        filterHitIndices = [Int]()
        for (index, value) in statementDataList.enumerated() {
            if value.statement.contains(keyword) {
                filterHitIndices.append(index)
            }
        }
    }
    
    func didChangeStatementData(obj: StatementRepository.Statement, documentChanges: [RepositoryDocumentChange<StatementRepository.StatementData>]) {
        let modifieds = documentChanges.filter { $0.type == .modified }
        modifieds.forEach { (modified) in
            if let index = statementDataList.firstIndex(where: { $0.id == modified.data.id }) {
                statementDataList[index] = modified.data
            }
        }
        
        let removesIds = documentChanges.filter { $0.type == .removed }.map { $0.data.id }
        var removedStatementList = [StatementRepository.StatementData]()
        statementDataList.forEach {
            if !removesIds.contains($0.id) {
                removedStatementList.append($0)
            }
        }
        statementDataList = removedStatementList
        
        let addeds = documentChanges.filter { $0.type == .added }
        addeds.forEach { (addedChange) in
            if addedChange.newIndex >= statementDataList.count {
                statementDataList.append(addedChange.data)
            } else {
                statementDataList.insert(addedChange.data, at: addedChange.newIndex)
            }
        }
        
        delegate?.didUpdateDataList(provider: self)
    }
}
