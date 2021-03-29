//
//  MeetingMemberIconContainer.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class MeetingMemberIconContainer: NSBox {
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    private let iconDefaultOffset: CGFloat = -12.0
    private var iconViewList = [MeetingMemberIconView]()
    
    func updateView(presenters: [MeetingMemberIconViewPresenter]) {
        iconViewList.forEach { $0.removeFromSuperview() }
        let imageViewSize = heightConstraint.constant
        let listCount = presenters.count
        let offset = imageViewSize * CGFloat(listCount) + iconDefaultOffset * CGFloat(listCount - 1) > widthConstraint.constant ? (widthConstraint.constant - (imageViewSize * CGFloat(listCount))) / CGFloat(listCount - 1) : iconDefaultOffset
        var sorted = presenters
        if let hostIndex = sorted.firstIndex(where: {$0.isHost()}) {
            let host = sorted[hostIndex]
            sorted.remove(at: hostIndex)
            sorted.insert(host, at: 0)
        }
        iconViewList = sorted.enumerated().compactMap {
            guard let iconView = MeetingMemberIconView.createFromNib(owner: self) else { return nil }
            let x = (imageViewSize + offset) * CGFloat($0.offset)
            iconView.setup(frame: NSRect(x: x, y: 0.0, width: imageViewSize, height: imageViewSize), presenter: $0.element)
            return iconView
        }
        iconViewList.reversed().forEach { addSubview($0) }
    }
}
