//
//  SelectMemberViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa

class SelectMemberViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    @IBOutlet weak var memberCollectionView: NSCollectionView!
    @IBOutlet weak var collectionClipView: NSClipView!
    @IBOutlet weak var fetchIndicator: NSProgressIndicator!
    
    private let cellId = "SelectMemberCollectionViewItem"
    private var userDataList = [SelectMemberCollectionData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cellNib = NSNib(nibNamed: cellId, bundle: nil)
        memberCollectionView.register(cellNib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
        memberCollectionView.dataSource = self
        memberCollectionView.delegate = self
        collectionClipView.offClipping()
        fetch()
    }
    
    private func fetch() {
        fetchIndicator.startAnimation(self)
        UserRepository().index { (result) in
            self.fetchIndicator.stopAnimation(self)
            switch result {
            case .success(let dataList):
                self.userDataList = dataList.map({ (userData) -> SelectMemberCollectionData in
                    return SelectMemberCollectionData(userData: userData, selected: false)
                })
                self.memberCollectionView.reloadData()
            case .failure(let error):
                AlertBuilder.createErrorAlert(title: "Error", message: "Failed to fetch member list. \(error.localizedDescription)").runModal()
            }
        }
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return userDataList.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = memberCollectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! SelectMemberCollectionViewItem
        let presenter = SelectMemberCollectionViewItemPresenter(data: userDataList[indexPath.item])
        item.updateView(presenter: presenter)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        indexPaths.forEach { (indexPath) in
            if let item = memberCollectionView.item(at: indexPath) as? SelectMemberCollectionViewItem {
                var data = userDataList[indexPath.item]
                data.selected = !data.selected
                userDataList[indexPath.item] = data
                let presenter = SelectMemberCollectionViewItemPresenter(data: data)
                item.updateView(presenter: presenter)
            }
        }
        memberCollectionView.deselectItems(at: indexPaths)
    }
}
