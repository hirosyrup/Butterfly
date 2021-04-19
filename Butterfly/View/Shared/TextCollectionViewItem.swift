//
//  TextCollectionViewItem.swift
//  comet
//
//  Created by 岩井 宏晃 on 2020/06/08.
//  Copyright © 2020 koalab. All rights reserved.
//

import Cocoa

class TextCollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak var background: NSBox!
    @IBOutlet weak var label: NSTextField!
    
    override var isSelected: Bool {
        didSet {
            setIdleColor()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.addTrackingArea(NSTrackingArea(rect: view.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: view, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !isSelected {
            background.fillColor = NSColor.cellBackground
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        setIdleColor()
    }
    
    func setLabelText(labelText: String) {
        label.stringValue = labelText
    }
    
    private func setIdleColor() {
        if isSelected {
            background.fillColor = NSColor.systemBlue
            label.textColor = NSColor.white
        } else {
            background.fillColor = NSColor.clear
            label.textColor = NSColor.textColor
        }
    }
}
