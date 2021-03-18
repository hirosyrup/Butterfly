//
//  UserRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation
import Hydra

class UserRepository {
    private let user = FirestoreUser()
    private var indexCompletion: ((Result<[UserData], Error>) -> Void)?
    private var findOrCreateCompletion: ((Result<UserData, Error>) -> Void)?
    private var saveCompletion: ((Result<UserData, Error>) -> Void)?
    
    func index(completion: @escaping (Result<[UserData], Error>) -> Void) {
        indexCompletion = completion
        async({ _ -> [UserData] in // you must specify the return of the Promise, here an Int
            return try await(self.user.index())
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
            var userData = try await(self.user.fetch(userId: userId))
            if userData == nil {
                var newUserData = UserData.new()
                newUserData = try await(self.user.save(data: newUserData, userId: userId))
                userData = newUserData
            }
            return userData!
        }).then({ userData in
            self.findOrCreateCompletion?(.success(userData))
        }).catch { (error) in
            self.findOrCreateCompletion?(.failure(error))
        }.always {
            self.findOrCreateCompletion = nil
        }
    }
    
    func save(userData: UserData, userId: String, compltion: @escaping (Result<UserData, Error>) -> Void) {
        saveCompletion = compltion
        async({ _ -> UserData in // you must specify the return of the Promise, here an Int
            return try await(self.user.save(data: userData, userId: userId))
        }).then({newUserData in
            self.saveCompletion?(.success(newUserData))
        }).catch { (error) in
            self.saveCompletion?(.failure(error))
        }.always {
            self.saveCompletion = nil
        }
    }
}
