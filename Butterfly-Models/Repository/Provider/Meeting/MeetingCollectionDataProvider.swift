//
//  MeetingCollectionDataProvider.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/04/21.
//

import Foundation

protocol MeetingCollectionDataProviderDelegate: class {
    func didUpdateDataList(provider: MeetingCollectionDataProvider)
}

class MeetingCollectionDataProvider: MeetingRepositoryDataListDelegate {
    weak var delegate: MeetingCollectionDataProviderDelegate?
    
    private var filteringKeyword = ""
    private var meetingDataList = [MeetingRepository.MeetingData]()
    private let meetingRepository = MeetingRepository.Meeting()
    private(set) var displayDataList = [MeetingRepository.MeetingData]()
    
    func changeSearchParams(workspaceId: String, startAt: Date?, endAt: Date?) {
        meetingDataList = []
        meetingRepository.unlisten()
        meetingRepository.listen(workspaceId: workspaceId, startAt: startAt, endAt: endAt, dataListDelegate: self)
    }
    
    func changeFilteringKeyword(keyword: String) {
        filteringKeyword = keyword
        updateDisplayDataList()
    }
    
    func didChangeMeetingDataList(obj: MeetingRepository.Meeting, documentChanges: [RepositoryDocumentChange<MeetingRepository.MeetingData>]) {
        let modifieds = documentChanges.filter { $0.type == .modified }
        modifieds.forEach { (modified) in
            if  self.meetingDataList.count > modified.oldIndex {
                self.meetingDataList[modified.oldIndex] = modified.data
            }
        }
        
        let removesIndex = documentChanges.filter { $0.type == .removed }.map { $0.oldIndex }
        var removedMeetingList = [MeetingRepository.MeetingData]()
        for (index, value) in meetingDataList.enumerated() {
            if !removesIndex.contains(index) {
                removedMeetingList.append(value)
            }
        }
        meetingDataList = removedMeetingList
        
        let addeds = documentChanges.filter { $0.type == .added }
        addeds.forEach { (addedChange) in
            if addedChange.newIndex >= meetingDataList.count {
                meetingDataList.append(addedChange.data)
            } else {
                meetingDataList.insert(addedChange.data, at: addedChange.newIndex)
            }
        }
        
        updateDisplayDataList()
    }
    
    private func updateDisplayDataList() {
        if filteringKeyword.isEmpty {
            displayDataList = meetingDataList
        } else {
            let keywords = filteringKeyword.split(separator: " ")
            displayDataList = meetingDataList.filter({ (data) -> Bool in
                let name = data.name
                var result = false
                keywords.forEach { (keyword) in
                    if name.contains(keyword) {
                        result = true
                        return
                    }
                }
                return result
            })
        }
        delegate?.didUpdateDataList(provider: self)
    }
}
