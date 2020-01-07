//
//  AlertsTableViewCell.swift
//  Cloudship
//
//  Created by Scott Kriss on 6/1/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

protocol AlertsCellDelegate {
    func didTapURLButton(url: String)
}

class AlertsTableViewCell: UITableViewCell {
    @IBOutlet weak var alertTitleLabel: UILabel!
    @IBOutlet weak var alertDescriptionLabel: UILabel!
    @IBOutlet weak var alertSeverityLabel: UILabel!
    @IBOutlet weak var alertEffectiveTime: UILabel!
    @IBOutlet weak var alertExpiresTime: UILabel!
 
    @IBOutlet weak var alertDescriptionTextView: UITextView!
    @IBOutlet weak var alertsMoreInfoButton: UIButton!
    
    var alertItem: Alerts!
    var delegate: AlertsCellDelegate?
    
    func setURL(url: Alerts) {
        alertItem = url
        
    }
    @IBAction func alertsURLButtonTapped(_ sender: Any) {
        delegate?.didTapURLButton(url: alertItem.uri)
        print("Did tap from cell")
    }
    
    
}
