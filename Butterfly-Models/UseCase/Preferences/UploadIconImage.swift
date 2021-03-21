//
//  UploadIconImage.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/16.
//

import Foundation
import Hydra

class UploadIconImage {
    private let uploadImageUrl: URL
    private let fileName: String?
    private var uploadCompletion: ((Result<UploadIconImageResponse, Error>) -> Void)?
    private let iconImage = IconImage.shared
    
    init(uploadImageUrl: URL, fileName: String?) {
        self.uploadImageUrl = uploadImageUrl
        self.fileName = fileName
    }
    
    func execute(completion: @escaping (Result<UploadIconImageResponse, Error>) -> Void) {
        uploadCompletion = completion
        async({ _ -> UploadIconImageResponse in // you must specify the return of the Promise, here an Int
            let savedName =  try await(self.iconImage.upload(uploadImageUrl: self.uploadImageUrl, fileName: self.fileName))
            let downloadUrl = try await(self.iconImage.fetchDownloadUrl(fileName: savedName))
            return UploadIconImageResponse(downloadUrl: downloadUrl, savedName: savedName)
        }).then({response in
            self.uploadCompletion?(.success(response))
        }).catch { (error) in
            self.uploadCompletion?(.failure(error))
        }.always {
            self.uploadCompletion = nil
        }
    }
}
