//
//  InfoViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 7/3/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import MessageUI
import UserNotifications

class InfoViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, MFMailComposeViewControllerDelegate {

    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var unitsLabel: UILabel!
    @IBOutlet var unitsTapRec: UITapGestureRecognizer!
//    @IBOutlet weak var alertTimePicker: UIDatePicker!
    @IBOutlet var alertTapRec: UITapGestureRecognizer!
    @IBOutlet weak var alertsLabel: UILabel!

    @IBOutlet weak var pickerDoneTextView: UITextField!
    
    //--------------------------------------------------------------------------
    // MARK: - Variables
    //--------------------------------------------------------------------------
    
    let units = ["USA (Fahenheit, miles, mph)", "SI (Celsius, km, m/s)"]
    let defaults = UserDefaults.standard
    var unitsSelected: String = ""
    let appVersion:String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    let appBuild:String = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
    var systemVersion = UIDevice.current.systemVersion
    var notificationGranted = false
    let alertTimePicker = UIDatePicker()
    var alertHour = 0
    var alertMin = 0
    
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
        let alertString = UserDefaults.standard.string(forKey: "alertStringDefault")
        alertsLabel.text = alertString
        
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
        
        setUpAlertPicker()
//        alertTimePicker.isHidden = true
//        let alertTap = UITapGestureRecognizer(target: self, action: #selector(InfoViewController.alertTapFunction))
//        alertsLabel.addGestureRecognizer(alertTap)

        registerLocal()
    }
    
    //--------------------------------------------------------------------------
    // MARK: - Functions
    //--------------------------------------------------------------------------
    @objc func registerLocal() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Yay!")
            } else {
                print("D'oh")
            }
        }
    }
    
    func setUpAlertPicker(){
    //ToolBar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        //done button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(self.doneDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(self.cancelDatePicker))
        toolbar.setItems([doneButton,spaceButton, cancelButton], animated: true)
        // add toolbar to textField
        pickerDoneTextView.inputAccessoryView = toolbar
        // add datepicker to textField
        pickerDoneTextView.inputView = alertTimePicker
        alertTimePicker.datePickerMode = .time

    }
    
    @objc func doneDatePicker() {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: alertTimePicker.date)
        var alertString = "   Weather alert set for: "
        alertString.append(timeString)
        
        alertsLabel.text = alertString
        defaults.set(alertString, forKey: "alertStringDefault")
        
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "HH"
        let hourString = hourFormatter.string(from: alertTimePicker.date)
        alertHour = Int(hourString)!
        
        let minFormatter = DateFormatter()
        minFormatter.dateFormat = "mm"
        let minString = minFormatter.string(from: alertTimePicker.date)
        alertMin = Int(minString)!
        
        //dismiss date picker dialog
        self.view.endEditing(true)
        
        scheduleLocal()
    }
    
    @objc func cancelDatePicker(){
        //cancel button dismiss datepicker dialog
        self.view.endEditing(true)
    }

    
    func scheduleLocal() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        let dataPoint = WeatherController.shared.weather
        let dailyTemp = String(format: "%.0f", (dataPoint?.daily?.data?[0].temperatureMax)!)
        let currentTemp = String(format: "%.0f", (dataPoint?.currently?.temperature)!)
        let dailyOutlook = dataPoint?.daily?.data?[0].summary
        var forcastString = "Currently: "
        forcastString.append(String(currentTemp))
        forcastString.append(". High Temp: ")
        forcastString.append(String(dailyTemp))
        forcastString.append(". ")
        forcastString.append(dailyOutlook!)
        
        content.title = "Daily Forcast"
        content.body = forcastString
        content.categoryIdentifier = "DailyAlert"
        content.sound = UNNotificationSound.default()
        
        
        var dateComponents = DateComponents()
//        dateComponents.calendar = Calendar.current
        dateComponents.hour = alertHour
        dateComponents.minute = alertMin
        print(dateComponents)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    
    func sendEmail () {
        let mailComposerVC = MFMailComposeViewController()
        var mailBodyFooter = ""
        
        mailBodyFooter.append("\n\n\n")
        mailBodyFooter.append("Version: " + appVersion)
        mailBodyFooter.append("\n")
        mailBodyFooter.append("Build #: " + appBuild)
        mailBodyFooter.append("\n")
        mailBodyFooter.append("System Version: " + systemVersion)
        
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["scottkriss@gmail.com"])
        mailComposerVC.setSubject("Cloudship feedback")
        mailComposerVC.setMessageBody(mailBodyFooter, isHTML: false)
        
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
    
    @objc func alertTapFunction() {
        print("Alerts Lable Tapped")
        alertTimePicker.isHidden = false
        view.addSubview(alertTimePicker)
        alertsLabel.isUserInteractionEnabled = true
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
