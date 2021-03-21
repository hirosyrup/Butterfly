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
    struct IconImageCache {
        let url: URL
        let expiredTime: TimeInterval
    }
    
    static let shared = IconImage()
    
    private let imageCache = NSCache<AnyObject, AnyObject>()
    
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
            if let cache = self.imageCache.object(forKey: fileName as AnyObject) as? IconImageCache {
                if Date().timeIntervalSince1970 > cache.expiredTime {
                    self.imageCache.removeObject(forKey: fileName  as AnyObject)
                } else {
                    resolve(cache.url)
                    return
                }
            }
            
            let ref = self.iconRef(fileName: fileName)
            ref.downloadURL { (url, error) in
                if let _error = error {
                    reject(_error)
                } else {
                    self.imageCache.setObject(IconImageCache(url: url!, expiredTime: self.createExpiredDateTimeInterval())as AnyObject, forKey: fileName as AnyObject)
                    resolve(url!)
                }
            }
        }
    }
    
    private func createExpiredDateTimeInterval() -> TimeInterval {
        return Calendar.current.date(byAdding: .minute, value: 30, to: Date())!.timeIntervalSince1970
    }
    
    private func iconRef(fileName: String) -> StorageReference  {
        return Storage.storage().reference().child("icons/\(fileName)")
    }
}
