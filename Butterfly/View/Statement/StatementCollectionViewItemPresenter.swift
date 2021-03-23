//
//  StatementCollectionViewItemPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Foundation

class StatementCollectionViewItemPresenter {
    private let data: StatementRepository.StatementData
    
    init(data: StatementRepository.StatementData) {
        self.data = data
    }
    
    func userName() -> String {
        return data.user.name
    }
    
    func iconImageUrl() -> URL? {
        return data.user.iconImageUrl
    }
    
    func statement() -> String {
        return data.statement
    }
}