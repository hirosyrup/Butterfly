//
//  StatementCollectionViewItemPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation

class StatementCollectionViewItemPresenter {
    private let data: StatementRepository.StatementData
    private let previousData: StatementRepository.StatementData?
    
    init(data: StatementRepository.StatementData, previousData: StatementRepository.StatementData?) {
        self.data = data
        self.previousData = previousData
    }
    
    func userName() -> String {
        if let user = data.user {
            return user.name
        } else {
            return DefaultUserName.name
        }
    }
    
    func iconImageUrl() -> URL? {
        if let user = data.user {
            return user.iconImageUrl
        } else {
            return nil
        }
    }
    
    func statement() -> String {
        return data.statement
    }
    
    func isOnlyStatement() -> Bool {
        guard let _previousData = previousData else {
            return false
        }
        return data.user?.id == _previousData.user?.id
    }
}
