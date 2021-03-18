//
//  MemberIconView.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa

class MemberIconView: NSView {
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconImageView: NSImageView!
    
    static func createFromNib(owner: Any?) -> MemberIconView? {
        var objects: NSArray? = NSArray()
        NSNib(nibNamed: "MemberIconView", bundle: nil)?.instantiate(withOwner: owner, topLevelObjects: &objects)
        return objects?.first{ $0 is MemberIconView } as? MemberIconView
    }
    
    func setCornerRadius(radius: CGFloat) {
        iconImageView.wantsLayer = true
        iconImageView.layer?.cornerRadius = radius - topConstraint.constant
    }
    
    func updateView(imageUrl: URL) {
        iconImageView.loadImageAsynchronously(url: imageUrl)
    }
}
