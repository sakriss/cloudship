//
//  CurrentlyTableViewCell.swift
//  Cloudship
//
//  Created by Scott Kriss on 6/5/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class CurrentlyTableViewCell: UITableViewCell {
    
    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var backgroundAnimatedImage: UIImageView!
    @IBOutlet weak var currentConditionLabel: UILabel!
    @IBOutlet weak var lowTempLabel: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var highTempLabel: UILabel!
    @IBOutlet weak var currentSummaryLabel: UILabel!
    @IBOutlet weak var minutelyLookingAheadLabel: UILabel!
    @IBOutlet weak var lookingAheadCollectionView: UICollectionView!

    @IBOutlet weak var radarButton: UIButton!
    @IBOutlet weak var dailyButton: UIButton!
    @IBOutlet weak var hourlyButton: UIButton!
    
    @IBOutlet weak var currentConditionsContainerView: UIView!
    @IBOutlet weak var alertViewContainer: UIView!
    @IBOutlet weak var alertHeaderLabel: UILabel!
    
    //--------------------------------------------------------------------------
    // MARK: - Actions
    //--------------------------------------------------------------------------
    @IBAction func alertActiveButton(_ sender: Any) {
        print("Alert button pressed")
    }
    
    
}
