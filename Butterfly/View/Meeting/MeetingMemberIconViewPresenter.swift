//
//  MeetingMemberIconViewPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/28.
//

import Foundation

protocol MeetingMemberIconViewPresenter {
    func iconImageUrl() -> URL?
    func showEnteringIcon() -> Bool
    func isHost() -> Bool
}
