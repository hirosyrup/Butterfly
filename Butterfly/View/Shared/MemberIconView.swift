//
//  MemberIconView.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa

class MemberIconView: NSView {
    @IBOutlet weak var iconImageView: NSImageView!
    
    static func createFromNib(owner: Any?) -> MemberIconView? {
        var objects: NSArray? = NSArray()
        NSNib(nibNamed: "MemberIconView", bundle: nil)?.instantiate(withOwner: owner, topLevelObjects: &objects)
        return objects?.first{ $0 is MemberIconView } as? MemberIconView
    }
    
    func setCornerRadius() {
        iconImageView.wantsLayer = true
        iconImageView.layer?.cornerRadius = iconImageView.bounds.width / 2.0
    }
    
    func updateView(imageUrl: URL) {
        iconImageView.loadImageAsynchronously(url: imageUrl)
    }
}
