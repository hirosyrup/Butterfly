//
//  UserRepository.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/15.
//

import Foundation
import Hydra

class UserRepository {
    private let user: FirestoreUser
    private var findOrCreateCompletion: ((Result<UserData, Error>) -> Void)?
    private var saveCompletion: ((Result<UserData, Error>) -> Void)?
    
    init(userId: String) {
        self.user = FirestoreUser(userId: userId)
    }
    
    func findOrCreate(completion: @escaping (Result<UserData, Error>) -> Void) {
        findOrCreateCompletion = completion
        async({ _ -> UserData in // you must specify the return of the Promise, here an Int
            var userData = try await(self.user.fetch())
            if userData == nil {
                var newUserData = UserData.new()
                newUserData = try await(self.user.save(data: newUserData))
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
    
    func save(userData: UserData, compltion: @escaping (Result<UserData, Error>) -> Void) {
        saveCompletion = compltion
        async({ _ -> UserData in // you must specify the return of the Promise, here an Int
            return try await(self.user.save(data: userData))
        }).then({newUserData in
            self.saveCompletion?(.success(newUserData))
        }).catch { (error) in
            self.saveCompletion?(.failure(error))
        }.always {
            self.saveCompletion = nil
        }
    }
}
