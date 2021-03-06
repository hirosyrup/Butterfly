//
//  CalcStatementCollectionItemHeight.swift
//  Butterfly
//
//  Created by 岩井 宏晃 on 2021/04/04.
//

import Foundation

class CalcStatementCollectionItemHeight {
    private var calcHeightView: StatementCollectionViewItem!
    private var didCalcHeightList = [(StatementCollectionViewItemPresenter, CGSize)]()
    
    init() {
        calcHeightView = StatementCollectionViewItem()
        calcHeightView.instantiateFromNib()
    }
    
    func calcSize(index: Int, presenter: StatementCollectionViewItemPresenter, width: CGFloat) -> CGSize {
        if index < didCalcHeightList.count {
            let prevPresenter = didCalcHeightList[index].0
            if prevPresenter.isOnlyStatement() == presenter.isOnlyStatement() && prevPresenter.statement() == presenter.statement() && didCalcHeightList[index].1.width == width {
                return didCalcHeightList[index].1
            }
        }
        let size = calcHeightView.calcSize(presenter: presenter, width: width)
        if index < didCalcHeightList.count {
            didCalcHeightList[index] = (presenter, size)
        } else {
            didCalcHeightList.append((presenter, size))
        }
        return size
    }
}
