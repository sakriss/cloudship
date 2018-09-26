//
//  InfoViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 7/3/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import MessageUI

class InfoViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, MFMailComposeViewControllerDelegate {

    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet var unitsTapRec: UITapGestureRecognizer!
    
    //--------------------------------------------------------------------------
    // MARK: - Variables
    //--------------------------------------------------------------------------
    
    let units = ["USA (Fahenheit, miles, mph)", "SI (Celsius, km, m/s)"]
    let defaults = UserDefaults.standard
    var unitsSelected: String = ""
    
    //--------------------------------------------------------------------------
    // MARK: - Actions
    //--------------------------------------------------------------------------
    @IBAction func emailButton(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            print("Should send email")
            sendEmail()
        } else {
            showSendMailErrorAlert()
            print("Mail services are not available")
        }
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
    
    //--------------------------------------------------------------------------
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        unitsToDisplay()
        unitsLabel.text = unitsSelected
        
        picker.dataSource = self
        picker.delegate = self
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            var buildString = "   Application version\n"
//            self.appVersionLabel.text = "   App Version \n   " + version
            buildString.append("   " + version)
            buildString.append(" (")
            buildString.append(build)
            buildString.append(")")
            self.appVersionLabel.text = buildString
            
        }
        
        picker.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(InfoViewController.tapFunction))
        unitsLabel.addGestureRecognizer(tap)
        unitsLabel.isUserInteractionEnabled = true
        

        // Do any additional setup after loading the view.
    }
    
    //--------------------------------------------------------------------------
    // MARK: - Functions
    //--------------------------------------------------------------------------
    
    func sendEmail () {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["scottkriss@gmail.com"])
        mailComposerVC.setSubject("Cloudship feedback")
        mailComposerVC.setMessageBody("Feedback here please", isHTML: false)
        
        present(mailComposerVC, animated: true)
        
    }
    
    func showSendMailErrorAlert() {
        let sendEmailErrorAlert = UIAlertController(title: "Could not send the Email", message: "Email is not set up on your device", preferredStyle: UIAlertControllerStyle.alert)
        sendEmailErrorAlert.addAction(UIAlertAction(title: "DISMISS", style: UIAlertActionStyle.default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(sendEmailErrorAlert, animated: true, completion: nil)
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            print("Mail cancelled")
        case MFMailComposeResult.saved.rawValue:
            print("Mail saved")
        case MFMailComposeResult.sent.rawValue:
            print("Mail sent")
        case MFMailComposeResult.failed.rawValue:
            print("Mail sent failure: %@", [error?.localizedDescription])
            showSendMailErrorAlert()
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
//        controller.dismiss(animated: true, completion: nil)

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
    
    //--------------------------------------------------------------------------
    // MARK: - Picker Setup
    //--------------------------------------------------------------------------
    
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
