//
//  VoiceprintStorage.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/29.
//

import Foundation
import FirebaseStorage
import Hydra

class VoiceprintStorage {
    func upload(dataUrl: URL, fileName: String) -> Promise<String> {
        return Promise<String>(in: .background, token: nil) { (resolve, reject, _) in
            do {
                let data = try Data(contentsOf: dataUrl)
                let ref = self.filesRef(fileName: fileName)
                ref.putData(data, metadata: nil) { (_, error) in
                    if let _error = error {
                        reject(_error)
                    } else {
                        resolve(fileName)
                    }
                }
            } catch {
                reject(error)
            }
        }
    }
    
    func fetchDownloadUrl(fileName: String) -> Promise<URL?> {
        return Promise<URL?>(in: .background, token: nil) { (resolve, reject, _) in
            let ref = self.filesRef(fileName: fileName)
            ref.downloadURL { (url, error) in
                if error != nil {
                    resolve(nil)
                } else {
                    resolve(url!)
                }
            }
        }
    }
    
    func delete(fileName: String) -> Promise<Void> {
        return Promise<Void>(in: .background, token: nil) { (resolve, reject, _) in
            let ref = self.filesRef(fileName: fileName)
            ref.delete { (error) in
                if let _error = error {
                    reject(_error)
                } else {
                    resolve(())
                }
            }
        }
    }
    
    private func filesRef(fileName: String) -> StorageReference  {
        return Storage.storage().reference().child("voicePrints/\(fileName)")
    }
}
