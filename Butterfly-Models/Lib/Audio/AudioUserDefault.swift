//
//  AudioUserDefault.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/29.
//

import Foundation

class AudioUserDefault {
    static let shared = AudioUserDefault()
    
    let userDefault = UserDefaults.standard
    
    let audioDataListKey = "audioDataList"
    
    init() {
        userDefault.register(defaults: [audioDataListKey: []])
    }
    
    func addAudioRecordData(audioData: AudioRecordData) {
        var list = audioRecordDataList()
        list.append(audioData)
        userDefault.setValue(list.map { $0.createToUserDefaultData() }, forKey: audioDataListKey)
    }
    
    func audioRecordDataList() -> [AudioRecordData] {
        if let dataList = userDefault.array(forKey: audioDataListKey) as? [[String: String]] {
            return dataList.map { AudioRecordData.createFromUserDefaultData(data: $0) }
        } else {
            return []
        }
    }
    
    func removeAudioRecordData(dataList: [AudioRecordData]) {
        let removeFileNames = dataList.map { $0.fileName }
        let list = audioRecordDataList()
        let updateList = list.filter { !removeFileNames.contains($0.fileName)  }
        userDefault.setValue(updateList.map { $0.createToUserDefaultData() }, forKey: audioDataListKey)
    }
    
    func clear(meetingId: String) {
        let updateDataList = audioRecordDataList().filter { $0.meetingId != meetingId }
        userDefault.setValue(updateDataList.map { $0.createToUserDefaultData() }, forKey: audioDataListKey)
    }
}
