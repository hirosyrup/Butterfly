//
//  AudioUploaderQueue.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/03/30.
//

import Foundation
import Hydra

class AudioUploaderQueue {
    static let shared = AudioUploaderQueue()
    private var uploaders = [AudioUploader]()
    
    func addUploader(userId: String, queueData: AudioUploaderQueueData) {
        let workspaceId = queueData.workspaceId
        let meetingData = queueData.meetingData
        guard uploaders.first(where: { $0.meetingId == meetingData.id }) == nil else { return }
        guard let userIndex = meetingData.userList.firstIndex(where: { $0.id == userId }) else { return }
        let recordDataList = AudioUserDefault.shared.audioRecordDataList().filter({ $0.meetingId == meetingData.id })
        guard !recordDataList.isEmpty else { return }
        
        let uploader = AudioUploader(meetingId: meetingData.id, recordDataList: recordDataList)
        uploaders.append(uploader)
        async({ _ -> Void in
            let fileInfo = try await(uploader.upload())
            try? FileManager.default.removeItem(at: fileInfo.0)
            var updateData = meetingData
            updateData.userList[userIndex].audioFileName = fileInfo.1
            try await(MeetingRepository.Meeting().update(workspaceId: workspaceId, meetingData: updateData))
        }).then({
            recordDataList.forEach { (data) in
                let outputUrl = AudioLocalUrl.createRecordDirectoryUrl().appendingPathComponent(data.fileName)
                try? FileManager.default.removeItem(at: outputUrl)
            }
            AudioUserDefault.shared.clear(meetingId: meetingData.id)
        })
    }
}
