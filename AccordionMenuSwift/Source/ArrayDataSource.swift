//
//  ArrayDataSource.swift
//  AccordionMenuSwift
//
//  Created by Victor Sigler Lopez on 12/11/16.
//  Copyright © 2016 Victor Sigler. All rights reserved.
//

import Foundation
import UIKit

protocol ArrayDataSourceDelegate: class {
    
    func insertRowsAt(_ indexPath: [IndexPath] )
    
    func deleteRowsAt(_ indexPath: [IndexPath] )
}

class ArrayDataSource<C1: UITableViewCell, C2: UITableViewCell, I1, I2> : NSObject, UITableViewDataSource {
    
    /// A typealias to the closure of the parent cell configuration
    typealias ConfigureParentCellClosure = (_ cellType: C1, _ element: I1) -> Void
    
    /// A typealias to the closure of the chidl cell configuration
    typealias ConfigureChildCellClosure = (_ cellType: C2, _ element: I2) -> Void
    
    /// The configureCell closure to handle the configuration of the parent cell
    fileprivate var configureParentCell: ConfigureParentCellClosure
    
    /// The configureCell closure to handle the configuration of the child cell
    fileprivate var configureChildCell: ConfigureChildCellClosure
    
    /// The items
    fileprivate var items: [Parent<I1, I2>]

    /// The cell identifier for the parent cell
    fileprivate let parentCellIdentifier: String
    
    /// The cell identifier for the child cell
    fileprivate let childCellIdentifier: String
    
    /// Define wether can exist several cells expanded or not.
    open var numberOfCellsExpanded: CellsExpanded = .one
    
    /// Constant to define the values for the tuple in case of not exist a cell expanded.
    fileprivate let NoCellExpanded = (-1, -1)
    
    /// The index of the last cell expanded and its parent.
    fileprivate var lastCellExpanded : (Int, Int)!
    
    /// The number of elements in the data source
    open var total = 0
    
    /// The delegate variable no notify
    weak var delegate: ArrayDataSourceDelegate?

    /**
     Initializer of the class
     
     - parameter items:          The items for the data source
     - parameter cellIdentifier: The cell identifier
     - parameter configureCell:  The closure to handle the configuration of the cell.
     
     */
    init(items: [Parent<I1, I2>], parentCellIdentifier: String, childCellIdentifier: String, configureParentCell: @escaping ConfigureParentCellClosure,
         configureChildCell: @escaping ConfigureChildCellClosure) {
        
        self.items = items
        self.childCellIdentifier = childCellIdentifier
        self.parentCellIdentifier = parentCellIdentifier
        self.configureParentCell = configureParentCell
        self.configureChildCell = configureChildCell
        
        super.init()
    }
    
    /**
     Get the item specified for the NSIndexPath
     
     - parameter indexPath: The NSIndexPath
     
     - returns: The element in the NSIndexPath
     */
    fileprivate func parentItemAtIndex(_ index: Int) -> Parent<I1, I2>{
        return self.items[index]
    }
    
    /**
     Get the item specified for the NSIndexPath
     
     - parameter indexPath: The NSIndexPath
     
     - returns: The element in the NSIndexPath
     */
    fileprivate func childItemAtIndexPath(_ indexPath: IndexPath, withParent parent: Int,
                                          actualPosition position: Int) -> I2 {
        
        return items[parent].childs[indexPath.row - position - 1]
    }
    
    // MARK: DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return total
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell : UITableViewCell!
        
        let (parent, isParentCell, actualPosition) = self.findParent(atIndex: indexPath.row)
        
        if !isParentCell {
            cell = tableView.dequeueReusableCell(withIdentifier: childCellIdentifier, for: indexPath)
            let item = childItemAtIndexPath(indexPath, withParent: parent, actualPosition: actualPosition)
            self.configureChildCell(cell as! C2, item)
            
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: parentCellIdentifier, for: indexPath) as! C1
            let item = parentItemAtIndex(parent)
            self.configureParentCell(cell as! C1, item.element)
        }
        
        return cell as UITableViewCell
    }
}

extension ArrayDataSource {
    
    /**
     Find the parent position in the initial list, if the cell is parent and the actual position in the actual list.
     
     - parameter index: The index of the cell
     
     - returns: A tuple with the parent position, if it's a parent cell and the actual position righ now.
     */
    func findParent(atIndex index : Int) -> (parent: Int, isParentCell: Bool, actualPosition: Int) {
        
        var position = 0
        var parent = 0
        
        guard position < index else { return (parent, true, parent) }
        
        var item = parentItemAtIndex(parent)
        
        repeat {
            
            switch (item.state) {
            case .expanded:
                position += item.childs.count + 1
            case .collapsed:
                position += 1
            }
            
            parent += 1
            
            // if is not outside of dataSource boundaries
            if parent < self.items.count {
                item = parentItemAtIndex(parent)
            }
            
        } while (position < index)
        
        // if it's a parent cell the indexes are equal.
        if position == index {
            return (parent, position == index, position)
        }
        
        item = parentItemAtIndex(parent - 1)
        return (parent - 1, position == index, position - item.childs.count - 1)
    }
    
    /**
     Expand the cell at the index specified.
     
     - parameter index: The index of the cell to expand.
     */
    private func expandCell(atIndex index : Int, withParent parent: Int) {
        
        var item = parentItemAtIndex(parent)
        
        // the data of the childs for the specific parent cell.
        let currentSubItems = item.childs
        
        // update the state of the cell.
        item.state = .expanded
        
        // position to start to insert rows.
        var insertPos = index + 1
        
        let indexPaths = (0..<currentSubItems.count).map { _ -> IndexPath in
            let indexPath = IndexPath(row: insertPos, section: 0)
            insertPos += 1
            return indexPath
        }
        
        // insert the new rows
        delegate?.insertRowsAt(indexPaths)
        
        // update the total of rows
        self.total += currentSubItems.count
    }
    
    /**
     Collapse the cell at the index specified.
     
     - parameter index: The index of the cell to collapse
     */
    private func collapseSubItemsAtIndex(_ index : Int, parent: Int) {
        
        var indexPaths = [IndexPath]()
        
        var item = parentItemAtIndex(parent)
        
        let numberOfChilds = item.childs.count
        
        // update the state of the cell.
        item.state = .collapsed
        
        guard index + 1 <= index + numberOfChilds else { return }
        
        // create an array of NSIndexPath with the selected positions
        indexPaths = (index + 1...index + numberOfChilds).map { IndexPath(row: $0, section: 0)}
        
        // remove the expanded cells
        
        delegate?.deleteRowsAt(indexPaths)
        
        // update the total of rows
        self.total -= numberOfChilds
    }

    /**
     Update the cells to expanded to collapsed state in case of allow severals cells expanded.
     
     - parameter parent: The parent of the cell
     - parameter index:  The index of the cell.
     */
    func updateCells(forParent parent: Int, atIndex index: Int) {
        
        let item = parentItemAtIndex(parent)
        
        switch (item.state) {
            
        case .expanded:
            self.collapseSubItemsAtIndex(index, parent: parent)
            self.lastCellExpanded = NoCellExpanded
            
        case .collapsed:
            switch (numberOfCellsExpanded) {
            case .one:
                // exist one cell expanded previously
                if self.lastCellExpanded != NoCellExpanded {
                    
                    let (indexOfCellExpanded, parentOfCellExpanded) = self.lastCellExpanded
                    
                    self.collapseSubItemsAtIndex(indexOfCellExpanded, parent: parentOfCellExpanded)
                    
                    // cell tapped is below of previously expanded, then we need to update the index to expand.
                    if parent > parentOfCellExpanded {
                        let item = parentItemAtIndex(parentOfCellExpanded)
                        let newIndex = index - item.childs.count
                        self.expandCell(atIndex: newIndex, withParent: parent)
                        self.lastCellExpanded = (newIndex, parent)
                    }
                    else {
                        self.expandCell(atIndex: index, withParent: parent)
                        self.lastCellExpanded = (index, parent)
                    }
                }
                else {
                    self.expandCell(atIndex: index, withParent: parent)
                    self.lastCellExpanded = (index, parent)
                }
            case .several:
                self.expandCell(atIndex: index, withParent: parent)
            }
        }
    }
}
