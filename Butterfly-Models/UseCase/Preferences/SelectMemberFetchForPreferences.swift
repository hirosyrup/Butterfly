//
//  SelectMemberFetchForPreferences.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import Hydra

class SelectMemberFetchForPreferences: SelectMemberFetchProtocol {
    private var originalUserDataList = [PreferencesRepository.UserData]()
    
    func fetchMembers() -> Promise<[SelectMemberUserData]> {
        return Promise<[SelectMemberUserData]>(in: .background, token: nil) { (resolve, reject, _) in
            async({ _ -> [PreferencesRepository.UserData] in
                return try await(PreferencesRepository.User().index())
            }).then({ dataList in
                self.originalUserDataList = dataList
                let selectMemberList = dataList.map({ (userData) -> SelectMemberUserData in
                    return SelectMemberUserData(id: userData.id, iconImageUrl: userData.iconImageUrl, name: userData.name)
                })
                resolve(selectMemberList)
            }).catch { (error) in
                reject(error)
            }
        }
    }
    
    func originalUserDataListAt(_ indices: [Int]) -> [PreferencesRepository.UserData] {
        return indices.map { self.originalUserDataList[$0] }
    }
}
