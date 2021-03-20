//
//  UserRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation
import Hydra

struct UserData {
    fileprivate let original: FirestoreUserData
    var iconName: String?
    var iconImageUrl: URL?
    var name: String
    
    init(iconImageUrl: URL?, original: FirestoreUserData? = nil) {
        self.iconImageUrl = iconImageUrl
        self.original = original ?? FirestoreUserData.new()
        self.iconName = self.original.iconName
        self.name = self.original.name
    }
    
    fileprivate func toFirestoreData() -> FirestoreUserData {
        var firestoreData = original
        firestoreData.iconName = iconName
        firestoreData.name = name
        return firestoreData
    }
}

class UserRepository {
    private let user = FirestoreUser()
    private let iconImage = IconImage()
    private var indexCompletion: ((Result<[UserData], Error>) -> Void)?
    private var findOrCreateCompletion: ((Result<UserData, Error>) -> Void)?
    private var saveCompletion: ((Result<UserData, Error>) -> Void)?
    
    func index(completion: @escaping (Result<[UserData], Error>) -> Void) {
        indexCompletion = completion
        async({ _ -> [UserData] in // you must specify the return of the Promise, here an Int
            let firestoreUserDatas = try await(self.user.index())
            return try firestoreUserDatas.map { (firestoreUserData) -> UserData in
                var data = UserData(iconImageUrl: nil, original: firestoreUserData)
                if let iconName = firestoreUserData.iconName {
                    let downloadUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                    data.iconName = iconName
                    data.iconImageUrl = downloadUrl
                }
                return data
            }
        }).then({ userDataList in
            self.indexCompletion?(.success(userDataList))
        }).catch { (error) in
            self.indexCompletion?(.failure(error))
        }.always {
            self.indexCompletion = nil
        }
    }
    
    func findOrCreate(userId: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        findOrCreateCompletion = completion
        async({ _ -> UserData in // you must specify the return of the Promise, here an Int
            var firestoreUserData = try await(self.user.fetch(userId: userId))
            if firestoreUserData == nil {
                var newUserData = FirestoreUserData.new()
                newUserData = try await(self.user.save(data: newUserData, userId: userId))
                firestoreUserData = newUserData
            }
            
            var userData = UserData(iconImageUrl: nil, original: firestoreUserData)
            
            if let iconName = firestoreUserData!.iconName {
                let downloadUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                userData.iconName = iconName
                userData.iconImageUrl = downloadUrl
            }
            
            return userData
        }).then({ userData in
            self.findOrCreateCompletion?(.success(userData))
        }).catch { (error) in
            self.findOrCreateCompletion?(.failure(error))
        }.always {
            self.findOrCreateCompletion = nil
        }
    }
    
    func update(userData: UserData, compltion: @escaping (Result<UserData, Error>) -> Void) {
        saveCompletion = compltion
        async({ _ -> UserData in
            let userId = userData.original.id
            let firestoreUserData = userData.toFirestoreData().copyCurrentAt()
            let savedFirestoreUserData = try await(self.user.save(data: firestoreUserData, userId: userId))
            
            var userData = UserData(iconImageUrl: nil, original: savedFirestoreUserData)
            
            if let iconName = savedFirestoreUserData.iconName {
                let downloadUrl = try await(self.iconImage.fetchDownloadUrl(fileName: iconName))
                userData.iconName = iconName
                userData.iconImageUrl = downloadUrl
            }
            
            return userData
        }).then({newUserData in
            self.saveCompletion?(.success(newUserData))
        }).catch { (error) in
            self.saveCompletion?(.failure(error))
        }.always {
            self.saveCompletion = nil
        }
    }
}
