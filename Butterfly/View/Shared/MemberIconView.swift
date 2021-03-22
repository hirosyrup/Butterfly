//
//  MemberIconView.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa

class MemberIconView: NSView {
    @IBOutlet weak var bgView: NSView!
    @IBOutlet weak var iconImageView: NSImageView!
    @IBOutlet weak var toolTipContainer: NSBox!
    @IBOutlet weak var toolTipLabel: NSTextField!
    @IBOutlet weak var imageTopConstraint: NSLayoutConstraint!
    
    static func createFromNib(owner: Any?) -> MemberIconView? {
        var objects: NSArray? = NSArray()
        NSNib(nibNamed: "MemberIconView", bundle: nil)?.instantiate(withOwner: owner, topLevelObjects: &objects)
        return objects?.first{ $0 is MemberIconView } as? MemberIconView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .cursorUpdate,
            .activeAlways
        ]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
        toolTipContainer.isHidden = true
        offClipping()
    }
    
    func setCornerRadius() {
        let bgRadius = bgView.bounds.width / 2.0
        bgView.wantsLayer = true
        bgView.layer?.cornerRadius = bgRadius
        iconImageView.wantsLayer = true
        iconImageView.layer?.cornerRadius = bgRadius - imageTopConstraint.constant
    }
    
    func updateView(imageUrl: URL?, toolTip: String) {
        if imageUrl != nil {
            iconImageView.loadImageAsynchronously(url: imageUrl!)
        } else {
            iconImageView.image = NSImage(named: "no-image")
        }
        toolTipLabel.stringValue = toolTip
    }
    
    override func mouseEntered(with event: NSEvent) {
        toolTipContainer.isHidden = toolTipLabel.stringValue.isEmpty
    }
    
    override func mouseExited(with event: NSEvent) {
        toolTipContainer.isHidden = true
    }
}
