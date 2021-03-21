//
//  SelectMemberViewController.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/03/18.
//

import Cocoa
import Hydra

protocol SelectMemberViewControllerDelegate: class {
    func didChangeSelectedUserList(vc: SelectMemberViewController, selectedIndices: [Int])
}

class SelectMemberViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    @IBOutlet weak var memberCollectionView: NSCollectionView!
    @IBOutlet weak var collectionClipView: NSClipView!
    @IBOutlet weak var fetchIndicator: NSProgressIndicator!
    
    private let cellId = "SelectMemberCollectionViewItem"
    private var userDataList = [SelectMemberCollectionData]()
    private var initialSelectedUserList = [SelectMemberUserData]()
    
    private(set) var selectMemberFetch: SelectMemberFetchProtocol!
    private weak var delegate: SelectMemberViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cellNib = NSNib(nibNamed: cellId, bundle: nil)
        memberCollectionView.register(cellNib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId))
        memberCollectionView.dataSource = self
        memberCollectionView.delegate = self
        collectionClipView.offClipping()
        fetch()
    }
    
    func setup(selectMemberFetch: SelectMemberFetchProtocol, userList: [SelectMemberUserData], delegate: SelectMemberViewControllerDelegate? = nil) {
        self.selectMemberFetch = selectMemberFetch
        self.initialSelectedUserList = userList
        self.delegate = delegate
    }
    
    private func fetch() {
        fetchIndicator.startAnimation(self)
        async({ _ -> [SelectMemberUserData] in
            return try await(self.selectMemberFetch.fetchMembers())
        }).then({ dataList in
            self.userDataList = dataList.map({ (userData) -> SelectMemberCollectionData in
                return SelectMemberCollectionData(userData: userData, selected: self.isAlreadySelected(data: userData))
            })
            self.memberCollectionView.reloadData()
        }).catch { (error) in
            AlertBuilder.createErrorAlert(title: "Error", message: "Failed to fetch member list. \(error.localizedDescription)").runModal()
        }.always(in: .main) {
            self.fetchIndicator.stopAnimation(self)
        }
    }
    
    func isAlreadySelected(data: SelectMemberUserData) -> Bool {
        return initialSelectedUserList.first(where: { $0.id == data.id }) != nil
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
        var selectedIndices = [Int]()
        for (index, value) in userDataList.enumerated() {
            if value.selected {
                selectedIndices.append(index)
            }
        }
        delegate?.didChangeSelectedUserList(vc: self, selectedIndices: selectedIndices)
        memberCollectionView.deselectItems(at: indexPaths)
    }
}
