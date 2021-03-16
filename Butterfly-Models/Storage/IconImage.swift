//
//  IconImage.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/16.
//

import Foundation
import FirebaseStorage
import Hydra

class IconImage {
    func upload(uploadImageUrl: URL, fileName: String?) -> Promise<String> {
        return Promise<String>(in: .background, token: nil) { (resolve, reject, _) in
            do {
                let data = try Data(contentsOf: uploadImageUrl)
                let saveName = fileName != nil ? fileName! : "\(UUID().uuidString).\(uploadImageUrl.pathExtension)"
                let ref = self.iconRef(fileName: saveName)
                ref.putData(data, metadata: nil) { (_, error) in
                    if let _error = error {
                        reject(_error)
                    } else {
                        resolve(saveName)
                    }
                }
            } catch {
                reject(error)
            }
        }
    }
    
    func fetchDownloadUrl(fileName: String) -> Promise<URL> {
        return Promise<URL>(in: .background, token: nil) { (resolve, reject, _) in
            let ref = self.iconRef(fileName: fileName)
            ref.downloadURL { (url, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    resolve(url!)
                }
            }
        }
    }
    
    private func iconRef(fileName: String) -> StorageReference  {
        return Storage.storage().reference().child("icons/\(fileName)")
    }
}
