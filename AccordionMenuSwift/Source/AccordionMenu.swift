//
//  AccordionMenu.swift
//  AccordionMenu
//
//  Created by Victor on 7/6/16.
//  Copyright © 2016 Victor Sigler. All rights reserved.
//

import UIKit

protocol AccordionMenuDelegate: class {
    
    func didSelectParentRowCellAt(_ indexPath: IndexPath)
    
    func didSelectChildRowCellAt(_ indexPath: IndexPath)
}

open class AccordionMenuController<C1: UITableViewCell, C2: UITableViewCell, I1, I2> : UITableViewController, ArrayDataSourceDelegate {
    
    var arrayDataSource: ArrayDataSource<C1, C2, I1, I2>!
    
    weak var delegate: AccordionMenuDelegate?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = arrayDataSource
    }
    
    // MARK: ArrayDataSourceProtocol
    
    func deleteRowsAt(_ indexPath: [IndexPath]) {
        tableView.deleteRows(at: indexPath, with: UITableViewRowAnimation.fade)
    }
    
    func insertRowsAt(_ indexPath: [IndexPath]) {
        tableView.insertRows(at: indexPath, with: UITableViewRowAnimation.fade)
    }
    
    // MARK: UITableViewDelegate
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let (parent, isParentCell, actualPosition) = arrayDataSource.findParent(atIndex: indexPath.row)
        
        guard isParentCell else {
            NSLog("A child was tapped!!!")
            
            // The value of the child is indexPath.row - actualPosition - 1
            //NSLog("The value of the child is \(self.dataSource[parent].childs[indexPath.row - actualPosition - 1])")
            
            return
        }
        
        delegate?.didSelectParentRowCellAt(indexPath)
        
        self.tableView.beginUpdates()
        arrayDataSource.updateCells(forParent: parent, atIndex: indexPath.row)
        self.tableView.endUpdates()
    }
    
    override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return !arrayDataSource.findParent(atIndex: indexPath.row).isParentCell ? 44.0 : 64.0
    }
}
