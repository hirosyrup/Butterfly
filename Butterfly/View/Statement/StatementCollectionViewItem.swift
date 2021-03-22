//
//  StatementCollectionViewItem.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/22.
//

import Cocoa

class StatementCollectionViewItem: NSCollectionViewItem {
    @IBOutlet weak var iconImageContainer: NSView!
    @IBOutlet weak var userNameLabel: NSTextField!
    @IBOutlet weak var statementLabel: NSTextField!
    weak var iconView: MemberIconView!
    
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
        
        setupIconView()
    }
    
    private func setupIconView() {
        guard let iconView = MemberIconView.createFromNib(owner: self) else { return }
        iconView.frame = iconImageContainer.bounds
        iconView.layoutSubtreeIfNeeded()
        iconImageContainer.addSubview(iconView)
        iconView.setCornerRadius()
        self.iconView = iconView
    }
    
    func updateView(presenter: StatementCollectionViewItemPresenter) {
        iconView.updateView(imageUrl: presenter.iconImageUrl(), toolTip: "")
        userNameLabel.stringValue = presenter.userName()
        statementLabel.stringValue = presenter.statement()
    }
    
    func calcSize(presenter: StatementCollectionViewItemPresenter) -> CGSize {
        updateView(presenter: presenter)
        view.layoutSubtreeIfNeeded()
        return view.bounds.size
    }
}
