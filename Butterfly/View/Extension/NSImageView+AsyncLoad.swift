//
//  NSImageView+AsyncLoad.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa

extension NSImageView {
    static let imageCache = NSCache<AnyObject, AnyObject>()
    
    func loadImageAsynchronously(url: URL) -> Void {
        if let imageFromCache = NSImageView.imageCache.object(forKey: url as AnyObject) as? NSImage {
            self.image = imageFromCache
            return
        }
        
        image = nil
        DispatchQueue.global().async {
            let imageData: Data? = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                if let data = imageData, let loadedImage = NSImage(data: data) {
                    self.image = loadedImage
                    NSImageView.imageCache.setObject(loadedImage, forKey: url as AnyObject)
                }
            }
        }
    }
}
