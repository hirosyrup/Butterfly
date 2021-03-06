//
//  SelectMemberCollectionViewItem.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa

class SelectMemberCollectionViewItem: NSCollectionViewItem {
    @IBOutlet weak var memberIconViewContainer: NSView!
    @IBOutlet weak var checkImageView: NSImageView!
    private weak var memberIconView: MemberIconView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkImageView.isHidden = true
        memberIconView = MemberIconView.createFromNib(owner: nil)
        memberIconViewContainer.addSubview(memberIconView)
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        memberIconView.frame = view.bounds
        memberIconView.layoutSubtreeIfNeeded()
        memberIconView.setCornerRadius()
        memberIconView.offClipping()
        memberIconViewContainer.offClipping()
        view.offClipping()
    }
    
    func updateView(presenter: SelectMemberCollectionViewItemPresenter) {
        memberIconView.updateView(imageUrl: presenter.iconURL(), toolTip: presenter.name())
        checkImageView.isHidden = !presenter.selected()
    }
}
