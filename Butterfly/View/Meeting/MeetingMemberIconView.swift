//
//  MeetingMemberIconView.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/28.
//

import Cocoa

class MeetingMemberIconView: NSView {
    @IBOutlet weak var memberIconContainer: NSView!
    @IBOutlet weak var isEnteringIconImageView: NSImageView!
    
    static func createFromNib(owner: Any?) -> MeetingMemberIconView? {
        var objects: NSArray? = NSArray()
        NSNib(nibNamed: "MeetingMemberIconView", bundle: nil)?.instantiate(withOwner: owner, topLevelObjects: &objects)
        return objects?.first{ $0 is MeetingMemberIconView } as? MeetingMemberIconView
    }
    
    func setup(frame: CGRect, presenter: MeetingMemberIconViewPresenter) {
        if let iconView = MemberIconView.createFromNib(owner: self) {
            let bounds = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            self.frame = bounds
            memberIconContainer.frame = bounds
            memberIconContainer.addSubview(iconView)
            iconView.frame = memberIconContainer.bounds
            layoutSubtreeIfNeeded()
            self.frame = frame // for reset x position
            iconView.setCornerRadius()
            iconView.updateView(imageUrl: presenter.iconImageUrl(), toolTip: "")
            isEnteringIconImageView.isHidden = !presenter.showEnteringIcon()
        }
    }
}
