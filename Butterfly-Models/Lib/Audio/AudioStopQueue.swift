//
//  AudioStopQueue.swift
//  Butterfly
//
//  Created by 岩井宏晃 on 2021/04/01.
//

import Foundation
import Hydra

class AudioStopQueue: MeetingRepositoryDataListDelegate {
    static let shared = AudioStopQueue()
    private var stoppingRecorderList = [AudioRecorder]()
    private var isStopping = false
    private var queueDataList = [AudioUploaderQueueData]()
    private var meetingRepositories = [MeetingRepository.Meeting]()
    var userId: String = ""
    
    func listenMeeting(workspaceIds: [String]) {
        meetingRepositories.forEach { $0.unlisten() }
        meetingRepositories = workspaceIds.map { (workspaceId) -> MeetingRepository.Meeting in
            let meeting = MeetingRepository.Meeting()
            meeting.listen(workspaceId: workspaceId, dataListDelegate: self)
            return meeting
        }
    }
    
    func stop(audioRecorder: AudioRecorder) {
        stoppingRecorderList.append(audioRecorder)
        mergeAudio()
    }
    
    func addUploadQueue(queueData: AudioUploaderQueueData) {
        queueDataList.append(queueData)
        if stoppingRecorderList.isEmpty {
           processUploadQueue()
        }
    }
    
    private func mergeAudio() {
        guard !isStopping else { return }
        guard let stoppingRecorder = stoppingRecorderList.first else { return }
        isStopping = true
        async({ _ -> Void in
            try await(stoppingRecorder.stop())
        }).then({ _ in
            self.stoppingRecorderList.remove(at: 0)
            self.isStopping = false
            if self.stoppingRecorderList.isEmpty {
                self.processUploadQueue()
            } else {
                self.mergeAudio()
            }
        }).catch { (error) in
            print("\(error.localizedDescription)")
        }
    }
    
    private func processUploadQueue() {
        queueDataList.forEach { AudioUploaderQueue.shared.addUploader(userId: userId, queueData: $0) }
        queueDataList = [AudioUploaderQueueData]()
    }
    
    func didChangeMeetingDataList(obj: MeetingRepository.Meeting, documentChanges: [RepositoryDocumentChange<MeetingRepository.MeetingData>]) {
        let modifieds = documentChanges.filter { $0.type == .modified }
        modifieds.forEach { (modified) in
            let data = modified.data
            if data.endedAt != nil {
                if data.userList.first(where: { $0.id == self.userId && $0.audioFileName == nil }) != nil {
                    self.addUploadQueue(queueData: AudioUploaderQueueData(workspaceId: obj.listenWorkspaceId!, meetingData: data))
                }
            }
        }
    }
}
