//
//  MinutelyViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 5/21/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class MinutelyViewController: UIViewController {
    
    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var minutelyTableView: UITableView!
    
    //--------------------------------------------------------------------------
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.minutelyTableView.rowHeight = UITableView.automaticDimension
        self.minutelyTableView.estimatedRowHeight = 80
    }
    

}

//--------------------------------------------------------------------------
// MARK: - TableView Data Source
//--------------------------------------------------------------------------
extension MinutelyViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

}
