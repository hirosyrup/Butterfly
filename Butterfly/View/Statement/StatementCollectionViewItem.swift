//
//  StatementCollectionViewItem.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class StatementCollectionViewItem: NSCollectionViewItem {
    @IBOutlet weak var background: NSBox!
    @IBOutlet weak var iconImageContainer: NSView!
    @IBOutlet weak var headerContainer: NSBox!
    @IBOutlet weak var userNameLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var statementLabel: NSTextField!
    @IBOutlet weak var copyToClipboardButton: NSButton!
    weak var iconView: MemberIconView!
    private var trackingArea: NSTrackingArea?
    
    func instantiateFromNib() {
        var objects: NSArray? = NSArray()
        NSNib(nibNamed: "StatementCollectionViewItem", bundle: nil)?.instantiate(withOwner: self, topLevelObjects: &objects)
        if let view = objects?.first(where: { $0 is NSView }) as? NSView {
            self.view = view
            setupIconView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        copyToClipboardButton.isHidden = true
        setupIconView()
    }
    
    override func mouseEntered(with event: NSEvent) {
        onMouse(on: true)
    }
    
    override func mouseExited(with event: NSEvent) {
        onMouse(on: false)
    }
    
    private func onMouse(on: Bool) {
        if on {
            background.isTransparent = false
            background.fillColor = NSColor.cellLightBackground
            copyToClipboardButton.isHidden = false
        } else {
            background.isTransparent = true
            background.fillColor = NSColor.clear
            copyToClipboardButton.isHidden = true
        }
    }
    
    private func setupIconView() {
        guard let iconView = MemberIconView.createFromNib(owner: self) else { return }
        iconView.frame = iconImageContainer.bounds
        iconView.layoutSubtreeIfNeeded()
        iconImageContainer.addSubview(iconView)
        iconView.setCornerRadius()
        self.iconView = iconView
    }
    
    func updateView(presenter: StatementCollectionViewItemPresenter, width: CGFloat) {
        onMouse(on: false)
        let isOnlyStatement = presenter.isOnlyStatement()
        headerContainer.isHidden = isOnlyStatement
        if !isOnlyStatement {
            iconView.updateView(imageUrl: presenter.iconImageUrl(), toolTip: "")
            userNameLabel.stringValue = presenter.userName()
        }
        timeLabel.stringValue = presenter.time()
        statementLabel.attributedStringValue = presenter.statement()
        
        let frame = view.frame
        view.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: width, height: frame.height)
        
        if let area = trackingArea {
            view.removeTrackingArea(area)
        }
        view.layoutSubtreeIfNeeded()
        trackingArea = NSTrackingArea(rect: view.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: view, userInfo: nil)
        view.addTrackingArea(trackingArea!)
    }
    
    func calcSize(presenter: StatementCollectionViewItemPresenter, width: CGFloat) -> CGSize {
        updateView(presenter: presenter, width: width)
        view.layoutSubtreeIfNeeded()
        return view.bounds.size
    }
    
    @IBAction func pushCopyToClipboard(_ sender: Any) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(statementLabel.stringValue, forType: .string)
    }
}
