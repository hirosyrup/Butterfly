//
//  AudioStorage.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/30.
//

import Foundation
import FirebaseStorage
import Hydra

class AudioStorage {
    func upload(uploadImageUrl: URL, fileName: String) -> Promise<String> {
        return Promise<String>(in: .background, token: nil) { (resolve, reject, _) in
            do {
                let data = try Data(contentsOf: uploadImageUrl)
                let ref = self.recordFilesRef(fileName: fileName)
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
            let ref = self.recordFilesRef(fileName: fileName)
            ref.downloadURL { (url, error) in
                if error != nil {
                    resolve(nil)
                } else {
                    resolve(url!)
                }
            }
        }
    }
    
    private func recordFilesRef(fileName: String) -> StorageReference  {
        return Storage.storage().reference().child("recordFiles/\(fileName)")
    }
}
