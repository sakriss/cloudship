//
//  InfoViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 7/3/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
    @IBOutlet weak var appVersionLabel: UILabel!
    
    @IBAction func emailUsButton(_ sender: UIButton) {
        
    }
    @IBAction func poweredByDarkSkyLinkButton(_ sender: UIButton) {
        if let url = NSURL(string: "https://darksky.net/poweredby/"){
            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
        }
    
    }
    @IBAction func rateAppButton(_ sender: UIButton) {
        //Add link to App Store for review
        
    }
    @IBAction func privacyPolicyButton(_ sender: UIButton) {
    }
    
    @IBAction func termsOfServiceButton(_ sender: UIButton) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appVersionLabel.text = "App version 1.0"
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
