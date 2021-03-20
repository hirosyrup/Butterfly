//
//  SelectMemberCollectionViewItemPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Foundation

class SelectMemberCollectionViewItemPresenter {
    private let data: SelectMemberCollectionData
    private var iconUrlCompletion: ((URL?) -> Void)?
    
    init(data: SelectMemberCollectionData) {
        self.data = data
    }
    
    func selected() -> Bool {
        return data.selected
    }
    
    func iconURL() -> URL? {
        return data.userData.iconImageUrl
    }
    
    func name() -> String {
        return data.userData.name
    }
}
