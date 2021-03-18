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
    
    func iconURL(completion: @escaping (URL?) -> Void) {
        if let iconName = data.iconName {
            iconUrlCompletion = completion
            IconImage().fetchDownloadUrl(fileName: iconName)
                .then(in: .main, { downloadUrl in
                    self.iconUrlCompletion?(downloadUrl)
                    self.iconUrlCompletion = nil
                })
        } else {
            completion(nil)
        }
    }
    
    func name() -> String {
        return data.name
    }
}
