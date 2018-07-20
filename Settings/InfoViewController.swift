//
//  InfoViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 7/3/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet var unitsTapRec: UITapGestureRecognizer!
    
    let units = ["USA (Fahenheit, miles, mph)", "SI (Celsius, km, m/s)"]
    let defaults = UserDefaults.standard
    var unitsSelected: String = ""
    
    
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
        unitsToDisplay()
        unitsLabel.text = unitsSelected
        
        picker.dataSource = self
        picker.delegate = self
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.appVersionLabel.text = "   App Version \n   " + version
        }
        
        picker.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(InfoViewController.tapFunction))
        unitsLabel.addGestureRecognizer(tap)
        unitsLabel.isUserInteractionEnabled = true
        

        // Do any additional setup after loading the view.
    }
    
    func unitsToDisplay() {
        print(UserDefaults.standard.string(forKey: "Units")!)
        if let userDef = UserDefaults.standard.string(forKey: "Units") {
            if userDef == "units=us" {
                unitsSelected = "   Units \n   USA (Fahenheit, miles, mph)"
            }
            
            if userDef == "units=si" {
                unitsSelected = "   Units \n   SI (Celsius, km, m/s)"
            }
        }
        
        
    }
    
    @objc func tapFunction() {
        picker.isHidden = false
        view.addSubview(picker)
        unitsLabel.isUserInteractionEnabled = true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return units[row]
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedRow = [row]
        
        if selectedRow == [0] {
            print("Selected row 0 - US")
            defaults.set("units=us", forKey: "Units")
            unitsLabel.text = "   Units \n   USA (Fahenheit, miles, mph)"
        } else{
            print("Selected row 1 - SI")
            defaults.set("units=si", forKey: "Units")
            unitsLabel.text = "   Units \n   SI (Celsius, km, m/s)"
        }

    }

}
