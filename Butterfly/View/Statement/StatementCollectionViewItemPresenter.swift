//
//  StatementCollectionViewItemPresenter.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class StatementCollectionViewItemPresenter {
    private let data: StatementRepository.StatementData
    private let previousData: StatementRepository.StatementData?
    private let meetingData: MeetingRepository.MeetingData
    private let filterKeyword: String
    
    init(data: StatementRepository.StatementData, previousData: StatementRepository.StatementData?, meetingData: MeetingRepository.MeetingData, filterKeyword: String) {
        self.data = data
        self.previousData = previousData
        self.meetingData = meetingData
        self.filterKeyword = filterKeyword
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
    
    func time() -> String {
        guard let startedAt = meetingData.startedAt else { return "" }
        let diff = Int(round(data.createdAt.timeIntervalSince1970 - startedAt.timeIntervalSince1970))
        let hour = diff / 3600
        let minutes = diff % 3600 / 60
        let second = diff % 60
        return "\(String(format: "%02d", hour)):\(String(format: "%02d", minutes)):\(String(format: "%02d", second))"
    }
    
    func statement() -> NSAttributedString {
        if !filterKeyword.isEmpty, let range = data.statement.range(of: filterKeyword) {
            let attributedString = NSMutableAttributedString(string: data.statement)
            attributedString.addAttribute(.backgroundColor, value: NSColor.systemYellow, range: NSRange(range, in: data.statement))
            return attributedString
        } else {
            return NSAttributedString(string: data.statement)
        }
    }
    
    func isOnlyStatement() -> Bool {
        guard let _previousData = previousData else {
            return false
        }
        return data.user?.id == _previousData.user?.id
    }
}
