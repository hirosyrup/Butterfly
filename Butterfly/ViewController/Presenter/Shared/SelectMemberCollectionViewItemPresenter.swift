//
//  SelectMemberCollectionViewItemPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Foundation

class SelectMemberCollectionViewItemPresenter {
    private let data: UserData
    private var iconUrlCompletion: ((URL?) -> Void)?
    
    init(data: UserData) {
        self.data = data
    }
    
    func iconURL() -> URL? {
        return data.iconImageUrl
    }
    
    func name() -> String {
        return data.name
    }
}
