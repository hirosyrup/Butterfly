//
//  AudioUploaderQueue.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/30.
//

import Foundation

class AudioUploaderQueue: MeetingRepositoryDataListDelegate {
    static let shared = AudioUploaderQueue()
    
    private var meetingRepositories = [MeetingRepository.Meeting]()
    private var uploaders = [AudioUploader]() 
    
    func listenMeeting(workspaceIds: [String]) {
        meetingRepositories.forEach { $0.unlisten() }
        meetingRepositories = workspaceIds.map { (workspaceId) -> MeetingRepository.Meeting in
            let meeting = MeetingRepository.Meeting()
            meeting.listen(workspaceId: workspaceId, dataListDelegate: self)
            return meeting
        }
    }
    
    func addUploader(meetingId: String) {
        guard uploaders.first(where: { $0.meetingId == meetingId }) == nil else { return }
        let recordDataList = AudioUserDefault.shared.audioRecordDataList().filter({ $0.meetingId == meetingId })
        guard !recordDataList.isEmpty else { return }
        
        
    }
    
    func didChangeMeetingDataList(obj: MeetingRepository.Meeting, documentChanges: [RepositoryDocumentChange<MeetingRepository.MeetingData>]) {
        let modifieds = documentChanges.filter { $0.type == .modified }
        modifieds.forEach { (modified) in
            if  self.meetingDataList.count > modified.oldIndex {
                self.meetingDataList[modified.oldIndex] = modified.data
            }
        }
    }
}
