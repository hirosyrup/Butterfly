//
//  AudioUploaderQueue.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/30.
//

import Foundation
import Hydra

class AudioUploaderQueue: MeetingRepositoryDataListDelegate {
    static let shared = AudioUploaderQueue()
    
    private var meetingRepositories = [MeetingRepository.Meeting]()
    private var uploaders = [AudioUploader]()
    var userId: String = ""
    
    func listenMeeting(workspaceIds: [String]) {
        meetingRepositories.forEach { $0.unlisten() }
        meetingRepositories = workspaceIds.map { (workspaceId) -> MeetingRepository.Meeting in
            let meeting = MeetingRepository.Meeting()
            meeting.listen(workspaceId: workspaceId, startAt: nil, endAt: nil, dataListDelegate: self)
            return meeting
        }
    }
    
    func addUploader(workspaceId: String, meetingData: MeetingRepository.MeetingData, meetingUserDataList: [MeetingUserRepository.MeetingUserData]) {
        guard uploaders.first(where: { $0.meetingId == meetingData.id }) == nil else { return }
        guard let userIndex = meetingUserDataList.firstIndex(where: { $0.userId == self.userId }) else { return }
        let recordDataList = AudioUserDefault.shared.audioRecordDataList().filter({ $0.meetingId == meetingData.id })
        guard !recordDataList.isEmpty else { return }
        
        let uploader = AudioUploader(meetingId: meetingData.id, recordDataList: recordDataList)
        uploaders.append(uploader)
        async({ _ -> Void in
            let fileInfo = try await(uploader.upload())
            try? FileManager.default.removeItem(at: fileInfo.0)
            var updateUserData = meetingUserDataList[userIndex]
            updateUserData.audioFileName = fileInfo.1
            try await(MeetingUserRepository.User().update(workspaceId: workspaceId, meetingId: meetingData.id, meetingUserData: updateUserData))
        }).then({
            recordDataList.forEach { (data) in
                let outputUrl = AudioLocalUrl.createRecordDirectoryUrl().appendingPathComponent(data.fileName)
                try? FileManager.default.removeItem(at: outputUrl)
            }
            AudioUserDefault.shared.clear(meetingId: meetingData.id)
        })
    }
    
    func didChangeMeetingDataList(obj: MeetingRepository.Meeting, documentChanges: [RepositoryDocumentChange<MeetingRepository.MeetingData>]) {
        let modifieds = documentChanges.filter { $0.type == .modified }
        modifieds.forEach { (modified) in
            let data = modified.data
            if data.endedAt != nil {
                async({ _ -> [MeetingUserRepository.MeetingUserData] in
                    return try await(MeetingUserRepository.User().index(workspaceId: obj.listenWorkspaceId!, meetingId: data.id))
                }).then({ meetingUserDataList in
                    if meetingUserDataList.first(where: { $0.userId == self.userId && $0.audioFileName == nil }) != nil {
                        self.addUploader(workspaceId: obj.listenWorkspaceId!, meetingData: data, meetingUserDataList: meetingUserDataList)
                    }
                })
            }
        }
    }
}
