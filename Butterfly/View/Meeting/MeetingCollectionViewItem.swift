//
//  MeetingCollectionViewItem.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class MeetingCollectionViewItem: NSCollectionViewItem {
    @IBOutlet weak var background: NSBox!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var createdAtLabel: NSTextField!
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var memberIconView: MemberIconContainer!
    private var id: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addTrackingArea(NSTrackingArea(rect: view.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: view, userInfo: nil))
        updateButtonHidden(hidden: true)
    }
    
    override func mouseEntered(with event: NSEvent) {
        background.isTransparent = false
        background.fillColor = NSColor.cellBackground
        updateButtonHidden(hidden: false)
    }
    
    override func mouseExited(with event: NSEvent) {
        background.isTransparent = true
        background.fillColor = NSColor.clear
        updateButtonHidden(hidden: true)
    }

    private func updateButtonHidden(hidden: Bool) {
        editButton.isHidden = hidden
        deleteButton.isHidden = hidden
    }
    
    func updateView(presenter: MeetingCollectionViewItemPresenter) {
        titleLabel.stringValue = presenter.title()
        createdAtLabel.stringValue = presenter.createdAt()
        memberIconView.updateView(imageUrls: presenter.imageUrls())
    }
    
    @IBAction func pushEdit(_ sender: Any) {
        
    }
    
    @IBAction func pushDelete(_ sender: Any) {
        
    }
}
