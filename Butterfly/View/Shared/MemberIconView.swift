//
//  MemberIconView.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa

class MemberIconView: NSView {
    @IBOutlet weak var iconImageView: NSImageView!
    @IBOutlet weak var toolTipContainer: NSBox!
    @IBOutlet weak var toolTipLabel: NSTextField!
    
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
    }
    
    func setCornerRadius() {
        iconImageView.wantsLayer = true
        iconImageView.layer?.cornerRadius = iconImageView.bounds.width / 2.0
    }
    
    func updateView(imageUrl: URL, toolTip: String) {
        iconImageView.loadImageAsynchronously(url: imageUrl)
        toolTipLabel.stringValue = toolTip
    }
    
    override func mouseEntered(with event: NSEvent) {
        toolTipContainer.isHidden = false
    }
    
    override func mouseExited(with event: NSEvent) {
        toolTipContainer.isHidden = true
    }
}
