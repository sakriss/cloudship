//
//  DailyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class DailyViewController: UIViewController {

    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var dailyForcastTableView: UITableView!
    @IBOutlet weak var dailySummaryLabel: UILabel!
    
    //--------------------------------------------------------------------------
    // MARK: - Variables
    //--------------------------------------------------------------------------
    var selectedRowIndex: NSIndexPath = NSIndexPath(row: -1, section: 0)
    var isExpanded = false

    //--------------------------------------------------------------------------
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dailyForcastTableView.rowHeight = UITableView.automaticDimension
        self.dailyForcastTableView.estimatedRowHeight = 115
    }

}

//--------------------------------------------------------------------------
// MARK: - Tableview Delegate
//--------------------------------------------------------------------------

extension DailyViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRowIndex = indexPath as NSIndexPath
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = tableView.cellForRow(at: indexPath)
        let cellHeight = row?.bounds.height
        let cell = tableView.cellForRow(at: indexPath) as? DailyTableViewCell
        
        if indexPath.row == selectedRowIndex.row {
            if cellHeight == 115 {
                
                cell?.dailyViewMoreLabel.text = "-"
                return 185
            }
            
        }
        cell?.dailyViewMoreLabel.text = "+"
        
        return 115
    }
}

//--------------------------------------------------------------------------
// MARK: - TableView Data Source
//--------------------------------------------------------------------------

extension DailyViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
