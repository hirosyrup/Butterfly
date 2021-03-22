//
//  MemberIconContainer.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class MemberIconContainer: NSBox {
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    private let iconDefaultOffset: CGFloat = -12.0
    private var iconViewList = [MemberIconView]()
    
    func updateView(imageUrls: [URL?]) {
        iconViewList.forEach { $0.removeFromSuperview() }
        let imageViewSize = heightConstraint.constant
        let listCount = imageUrls.count
        let offset = imageViewSize * CGFloat(listCount) + iconDefaultOffset * CGFloat(listCount - 1) > widthConstraint.constant ? (widthConstraint.constant - (imageViewSize * CGFloat(listCount))) / CGFloat(listCount - 1) : iconDefaultOffset
        iconViewList = imageUrls.enumerated().compactMap {
            guard let iconView = MemberIconView.createFromNib(owner: self) else { return nil }
            let x = (imageViewSize + offset) * CGFloat($0.offset)
            iconView.frame = NSRect(x: 0.0, y: 0.0, width: imageViewSize, height: imageViewSize)
            iconView.layoutSubtreeIfNeeded() // for resize
            iconView.frame = NSRect(x: x, y: 0.0, width: imageViewSize, height: imageViewSize) // for reset x position
            iconView.setCornerRadius()
            iconView.updateView(imageUrl: $0.element, toolTip: "")
            return iconView
        }
        iconViewList.reversed().forEach { addSubview($0) }
    }
}
