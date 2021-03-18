//
//  SelectMemberViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa

class SelectMemberViewController: NSViewController, NSCollectionViewDataSource {
    @IBOutlet weak var memberCollectionView: NSCollectionView!
    @IBOutlet weak var fetchIndicator: NSProgressIndicator!
    
    private let cellId = "SelectMemberCollectionViewItem"
    private var userDataList = [UserData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cellNib = NSNib(nibNamed: cellId, bundle: nil)
        memberCollectionView.register(cellNib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
        memberCollectionView.dataSource = self
        fetch()
    }
    
    private func fetch() {
        fetchIndicator.startAnimation(self)
        UserRepository().index { (result) in
            self.fetchIndicator.stopAnimation(self)
            switch result {
            case .success(let dataList):
                self.userDataList = dataList
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
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: 52.0, height: 52.0)
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = memberCollectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), for: indexPath) as! SelectMemberCollectionViewItem
        let presenter = SelectMemberCollectionViewItemPresenter(data: userDataList[indexPath.item])
        item.updateView(presenter: presenter)
        return item
    }
}
