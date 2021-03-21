//
//  SelectMemberFetchProtocol.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/21.
//

import Foundation
import Hydra

protocol SelectMemberFetchProtocol {
    func fetchMembers() -> Promise<[SelectMemberUserData]>
}
