//
//  ViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 1/30/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GoogleMobileAds

class ViewController: UIViewController, UISearchBarDelegate {
    
    //--------------------------------------------------------------------------
    // MARK: - Outlets
    //--------------------------------------------------------------------------
    
    @IBOutlet var currentTempContainerTapRec: UITapGestureRecognizer!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var currentlyTableView: UITableView!
    @IBOutlet weak var searchTableView: UITableView!
    
    //--------------------------------------------------------------------------
    // MARK: - Actions
    //--------------------------------------------------------------------------
    
    @IBAction func searchForLocationButton(_ sender: Any) {
        navigationController?.isNavigationBarHidden = true
        searchTableView.isHidden = false
        searchBar.isHidden = false
        searchTableView.reloadData()
    }
    
    //--------------------------------------------------------------------------
    // MARK: - Variables
    //--------------------------------------------------------------------------
    let defaults = UserDefaults.standard
    var searchActive : Bool = false
    var matchingItems:[MKMapItem] = []
    var lastLocation: CLLocation? = nil
    var chosenLocation: CLLocation? = nil
    var lastLocationString: String = ""
    var nearestStorm = 0.0
    var bannerView: GADBannerView!
    
    private let refreshControl = UIRefreshControl()
    private let sharedDefaults = UserDefaults(suiteName: "group.happygiraffe.Cloudship-test")
    
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    
    let locationManager = CLLocationManager()
    var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    var homeLocationTitle = NSMutableAttributedString(string: "---Last Location---")
    
    //--------------------------------------------------------------------------
    // MARK: - View Lifecycle
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false

        var units = defaults.string(forKey: "Units")
        
        searchTableView.tableFooterView = UIView()
        searchTableView.isHidden = true
        searchBar.delegate = self
        searchBar.isHidden = true
        
        loadingDataAnimation()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.requestWhenInUseAuthorization()
         let authStatus = CLLocationManager.authorizationStatus()
               
               if authStatus == .notDetermined {
                   locationManager.requestWhenInUseAuthorization()
               } else {
                   locationManager.requestLocation()
               }
        
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataFetched) , name: WeatherController.weatherDataParseComplete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(weatherDataFailed) , name: WeatherController.weatherDataParseFailed, object: nil)
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 213/255, green: 220/255, blue: 232/255, alpha: 1)]
        refreshControl.tintColor = UIColor(red: 213/255, green: 220/255, blue: 232/255, alpha: 1)
        refreshControl.backgroundColor = UIColor(red: 120/255, green: 135/255, blue: 171/255, alpha: 1)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh weather info...", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(refreshData), for: UIControl.Event.valueChanged)
        self.currentlyTableView.addSubview(refreshControl)
        
        // In this case, we instantiate the banner with desired ad size.
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.adUnitID = "ca-app-pub-8795986379052808/6427921529"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        addBannerViewToView(bannerView)
    }
    
    //--------------------------------------------------------------------------
    // MARK: - Functions
    //--------------------------------------------------------------------------
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        if #available(iOS 11.0, *) {
            // In iOS 11, we need to constrain the view to the safe area.
            positionBannerViewFullWidthAtBottomOfSafeArea(bannerView)
        }
        else {
            // In lower iOS versions, safe area is not available so we use
            // bottom layout guide and view edges.
            positionBannerViewFullWidthAtBottomOfView(bannerView)
        }
    }
    
    @available (iOS 11, *)
    func positionBannerViewFullWidthAtBottomOfSafeArea(_ bannerView: UIView) {
        // Position the banner. Stick it to the bottom of the Safe Area.
        // Make it constrained to the edges of the safe area.
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            guide.leftAnchor.constraint(equalTo: bannerView.leftAnchor),
            guide.rightAnchor.constraint(equalTo: bannerView.rightAnchor),
            guide.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor)
            ])
    }
    
    func positionBannerViewFullWidthAtBottomOfView(_ bannerView: UIView) {
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: view.safeAreaLayoutGuide.bottomAnchor,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0))
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        clearSearchResults()
    }
    
//    func handleTap(gestureRecognizer: UIGestureRecognizer) {
//        let alertController = UIAlertController(title: nil, message: "You tapped at \(gestureRecognizer.location(in: self.view))", preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in }))
//        self.present(alertController, animated: true, completion: nil)
//    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            if response == nil {
                print("Error gathering new location")
            }else {
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                let geoCoder = CLGeocoder()
                let location = CLLocation(latitude: latitude!, longitude: longitude!)
                geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                    
                    if let placemarks = placemarks {
                        for placemark in placemarks {
                            var addressString = placemark.locality ?? ""
                            addressString.append(", ")
                            addressString.append(placemark.administrativeArea ?? "")
                            
                        }
                    }
                })
                
                self.matchingItems = (response?.mapItems)!
                self.searchTableView.reloadData()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchTableView.isHidden = true
        let units = defaults.string(forKey: "Units")
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            if response == nil {
                print("Error gathering new location")
            }else {
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude

//                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
                WeatherController.shared.fetchWeatherInfo(latitude: latitude!, longitude: longitude!, units: units!)
                //self.navigationItem.title = searchBar.text

                let geoCoder = CLGeocoder()
                let location = CLLocation(latitude: latitude!, longitude: longitude!)
                geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in

                    if let placemarks = placemarks {
                        for placemark in placemarks {
                            var addressString = placemark.locality ?? ""
                            addressString.append(", ")
                            addressString.append(placemark.administrativeArea ?? "")

                            self.navigationItem.title = addressString

                        }
                    }
                })
                
            }
            self.clearSearchResults()
        }
        
    }
    
    func loadingDataAnimation() {
        
        //*** small alert on load with blur background ***/
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        let alert = UIAlertController(title: nil, message: "Gathering weather...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating()
        view.addSubview(blurEffectView)
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        
    }
    
    @objc func refreshData(sender:AnyObject) {
        DispatchQueue.main.async {
            self.refreshControl.beginRefreshing()
        }
        locationManager.requestLocation()

    }
    
    @objc func weatherDataFetched () {
        
        //now that data is parsed, we can display it
        DispatchQueue.main.async {
            self.dismiss(animated: false, completion: nil)
            self.view.subviews.compactMap {  $0 as? UIVisualEffectView }.forEach {
                $0.removeFromSuperview()
            }
//            self.activityIndicator.removeFromSuperview()
            self.currentlyTableView.reloadData()

            self.refreshControl.endRefreshing()
        }
        
        let dataPoint = WeatherController.shared.weather
        let dataPointCurrent = WeatherController.shared.weatherbitWeatherCurrent
        
        if let currentTemp = dataPoint?.currently?.temperature {
            let formattedTemp = String(format: "%.0f", currentTemp)
            sharedDefaults?.set(formattedTemp, forKey: "currentTemp")
        }
        
        if let currentSummary = dataPoint?.minutely?.summary {
            sharedDefaults?.set(currentSummary, forKey: "currentSummary")
        }
        
        let conditionIcon = dataPoint?.currently?.icon
        switch conditionIcon {
        case "partly-cloudy-day":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "partly-cloudy-night":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "cloudy":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "clear-day":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "clear-night":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "rain":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "snow":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "sleet":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "wind":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        case "fog":
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
            
        default:
            sharedDefaults?.set(conditionIcon, forKey: "currentIcon")
        }
            
        
        if let nearestStormDistance = WeatherController.shared.weather?.currently?.nearestStormDistance {
            nearestStorm = nearestStormDistance
        }
    }
    
    @objc func weatherDataFailed () {
        //now that data fetch failed, do something about it
        DispatchQueue.main.async {
            //dismiss the alert
            self.dismiss(animated: false, completion: nil)
            
            //display the alert
            let alert = UIAlertController(title: "Error gathering weather", message: "Please make sure you're connected to the internet and tap Try Again", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { action in
                switch action.style{
                case .default:
                    
                    //remove the UIViews
                    self.view.subviews.compactMap {  $0 as? UIVisualEffectView }.forEach {
                        $0.removeFromSuperview()
                    }

                    //initiate the refreshdata call and start the animation
                    self.refreshData(sender: AnyObject.self as AnyObject)
                    self.loadingDataAnimation()

                    print("default")
                    
                case .cancel:
                    print("cancel")
                    
                case .destructive:
                    print("destructive")
                    
                    
                }}))
            self.present(alert, animated: true, completion: nil)
//            self.view.subviews.compactMap {  $0 as? UIVisualEffectView }.forEach {
//                $0.removeFromSuperview()
//            }

            self.currentlyTableView.reloadData()
            
            self.refreshControl.endRefreshing()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "currentlyToRadarSegue", let vc = segue.destination as? RadarViewController {
            if let userLoc = chosenLocation {
                vc.userLocation = userLoc
            }
        }
    }
    
    @objc func handleTap(gestureRecognizer: UIGestureRecognizer)
    {
        
        print("Tapped")
    }
    
    func clearSearchResults(){
        
        self.matchingItems.removeAll()
        self.searchTableView.reloadData()
        self.searchBar.text = ""
        self.searchBar.isHidden = true
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
        navigationController?.isNavigationBarHidden = false
        searchTableView.isHidden = true

    }
}

//--------------------------------------------------------------------------
// MARK: - Location Manager Delegate
//--------------------------------------------------------------------------
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationAuthStatus = status
        if status == .authorizedWhenInUse {
            print("We can now get your location")
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let units = defaults.string(forKey: "Units")
        for location in locations {
            print("\(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            lastLocation = location
            chosenLocation = location
            WeatherController.shared.fetchWeatherInfo(latitude: location.coordinate.latitude, longitude:location.coordinate.longitude, units: units!)
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarks:[CLPlacemark]?, error: Error?) in
                if let error = error {
                    print(error)
                    return
                }
                if let placemarks = placemarks {
                    for placemark in placemarks {
                        var addressString = placemark.subThoroughfare ?? ""
                        addressString.append(" ")
                        addressString.append(placemark.thoroughfare ?? "")
                        addressString.append(", ")
                        addressString.append(placemark.locality ?? "")
//                        addressString.append(", ")
//                        addressString.append(placemark.administrativeArea ?? "")
                        
                        self.navigationItem.title = addressString
                        self.lastLocationString = addressString

                    }
                }
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

//--------------------------------------------------------------------------
// MARK: - TableView Delegate
//--------------------------------------------------------------------------

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if currentlyTableView == tableView {
            return currentlyTableView.bounds.size.height - 60
        }
        if searchTableView == tableView {
            return 40
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchTableView == tableView {
            let units = defaults.string(forKey: "Units")
            
            let latitude: Double
            let longitude: Double
            
            if indexPath.row < matchingItems.count {
                let selectedSearchItem = matchingItems[indexPath.row].placemark
                latitude = selectedSearchItem.coordinate.latitude
                longitude = selectedSearchItem.coordinate.longitude
                let lastLoc = CLLocation(latitude: latitude, longitude: longitude)
                chosenLocation = lastLoc
            }else {

                latitude = (lastLocation?.coordinate.latitude)!
                longitude = (lastLocation?.coordinate.longitude)!
                let lastLoc = CLLocation(latitude: latitude, longitude: longitude)
                chosenLocation = lastLoc
            }
            
            WeatherController.shared.fetchWeatherInfo(latitude: latitude, longitude: longitude, units: units!)
            
            let geoCoder = CLGeocoder()
            let location = CLLocation(latitude: latitude, longitude: longitude)
            geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                
                if let placemarks = placemarks {
                    for placemark in placemarks {
                        var addressString = placemark.locality ?? ""
                        addressString.append(", ")
                        addressString.append(placemark.administrativeArea ?? "")
                        
                        self.navigationItem.title = addressString
                        
                    }
                }
            })
            clearSearchResults()
            
        }
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if searchTableView == tableView {
//            return "Last Location " + lastLocationString
//        }
//        else{
//            return nil
//        }
//    }
    

}

//--------------------------------------------------------------------------
// MARK: - TableView Data Source
//--------------------------------------------------------------------------

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == currentlyTableView {
            return 1
        }
        if tableView == searchTableView {
            return matchingItems.count + 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var returnedCell = UITableViewCell()
        
        if tableView == currentlyTableView {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CurrentlyTableViewCell", for: indexPath) as? CurrentlyTableViewCell else {
            return UITableViewCell()
        }
        cell.alertViewContainer.isHidden = true
        
        let dataPoint = WeatherController.shared.weather
        let dataPointCurrent = WeatherController.shared.weatherbitWeatherCurrent
        let dataPointDaily = WeatherController.shared.weatherbitWeatherDaily
        let dataPointHourly = WeatherController.shared.weatherbitWeatherHourly
        let dataPointAlert = WeatherController.shared.weatherbitWeatherAlerts
        
            if let currentTemp = dataPointCurrent?.data?[0].app_temp {
            let newCurrentTemp = String(format: "%.0f", currentTemp)
                cell.currentTempLabel.text = newCurrentTemp
        }
        
            if let currentCondition = dataPointCurrent?.data?[0].weather?.descriptionField {
                cell.currentConditionLabel.text = String(currentCondition)
        }
        
            if let highTemp = dataPointDaily?.data?[0].appMaxTemp {
            let newHighTemp = String(format: "%.0f", highTemp)
                cell.highTempLabel.text = newHighTemp + "\u{00B0}"
        }
        
            if let lowTemp = dataPointDaily?.data?[0].appMinTemp {
            let newLowTemp = String(format: "%.0f", lowTemp)
                cell.lowTempLabel.text = newLowTemp + "\u{00B0}"
        }
        
        if let currentSummary = dataPoint?.daily?.data?[indexPath.row].summary {
                cell.minutelyLookingAheadLabel.text = String(currentSummary)
        }
        
        if let lookingAhead = dataPoint?.minutely?.summary {
            cell.currentSummaryLabel.text = lookingAhead
        }
            let alertsCount = dataPointAlert?.alerts?.count ?? 0
            if alertsCount >= 1 {
                cell.alertViewContainer.isHidden = false
            }
//            if let alertsActive = dataPointAlert?.alerts?[0].descriptionField {
//            print(alertsActive)
//                cell.alertViewContainer.isHidden = false
//        }
        
        //load animated gif
        //TODO: load animation based on current weather conditions
        //cell.backgroundAnimatedImage.loadGif(asset: "cloudygif")
        let conditionIcon = dataPointCurrent?.data?[indexPath.row].weather?.icon
        switch conditionIcon {
        case "t01d", "t02d", "t03d":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudybackground")
        case "t01n","t02n", "t03n":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudynightbackground")
        case "t04d","t05d":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudybackground")
        case "t04n","t05n":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudynightbackground")
        case "d01d","d02d", "d03d":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainbackground")
        case "d01n","d02n", "d03n":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainbackground")
        case "r01d","r02d", "r03d":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainbackground")
        case "r01n","r02n", "r03n":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainbackground")
        case "f01d","r04d","r05d","r06d":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainbackground")
        case "f01n","r04n","r05n","r06n":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainbackground")
        case "s01d","s02d","s03d","s04d","s05d":
            cell.backgroundAnimatedImage.image = UIImage(named: "snowbackground")
         case "s01n","s02n","s03n","s04n","s05n":
            cell.backgroundAnimatedImage.image = UIImage(named: "snowbackground")
         case "a01d","a02d","a03d","a04d","a05d", "a06d":
            cell.backgroundAnimatedImage.image = UIImage(named: "fogbackground")
        case "a01n","a02n","a03n","a04n","a05n", "a06n":
            cell.backgroundAnimatedImage.image = UIImage(named: "fogbackground")
        case "c01d":
            cell.backgroundAnimatedImage.image = UIImage(named: "rainierbackground")
        case "c02d","c03d":
            cell.backgroundAnimatedImage.image = UIImage(named: "mostlycloudybackground")
        case "c04d":
            cell.backgroundAnimatedImage.image = UIImage(named: "mostlycloudybackground")
        case "c01n":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudynightbackground")
        case "c02n","c03n":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudynightbackground")
        case "c04n":
            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudynightbackground")
        default:
            cell.backgroundAnimatedImage.image = UIImage(named: "rainierbackground")
            
//        case "partly-cloudy-day":
//            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudybackground")
//        case "partly-cloudy-night":
//            cell.backgroundAnimatedImage.image = UIImage(named: "partlycloudynightbackground")
//        case "clear-day":
//            cell.backgroundAnimatedImage.image = UIImage(named: "rainierbackground")
//        case "clear-night":
//            cell.backgroundAnimatedImage.image = UIImage(named: "clearnightbackground")
//        case "rain":
//            cell.backgroundAnimatedImage.image = UIImage(named: "rainbackground")
//        case "snow":
//            cell.backgroundAnimatedImage.image = UIImage(named: "snowbackground")
//        case "sleet":
//            cell.backgroundAnimatedImage.image = UIImage(named: "sleetbackground")
//        case "wind":
//            cell.backgroundAnimatedImage.image = UIImage(named: "windybackground")
//        case "fog":
//            cell.backgroundAnimatedImage.image = UIImage(named: "fogbackground")
//        default:
//            cell.backgroundAnimatedImage.image = UIImage(named: "rainierbackground")
        }
            
            cell.dailyButton.layer.cornerRadius = 7
            cell.dailyButton.layer.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 0.25).cgColor
            cell.dailyButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
            
            cell.hourlyButton.layer.cornerRadius = 7
            cell.hourlyButton.layer.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 0.25).cgColor
            cell.hourlyButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
            
            cell.radarButton.layer.cornerRadius = 7
            cell.radarButton.layer.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 0.25).cgColor
            cell.radarButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
            
        cell.lookingAheadCollectionView.reloadData()
            
        returnedCell = cell
        }else if tableView == searchTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableViewCell", for: indexPath) as? SearchTableViewCell else {
                return UITableViewCell()
            }
            if indexPath.row < matchingItems.count {
                let selectedItem = matchingItems[indexPath.row].placemark
                cell.searchTitleLabel?.text = selectedItem.name
                cell.searchDetailsLabel?.text = selectedItem.title
            }else {
                cell.searchTitleLabel.attributedText = homeLocationTitle
                cell.searchDetailsLabel.text = lastLocationString
//                cell.backgroundColor = UIColor(red: 22/255, green: 41/255, blue: 85/255, alpha: 1)
            }
            returnedCell = cell
        }
        return returnedCell
    }

    
}

//--------------------------------------------------------------------------
// MARK: - Collection View Data Source
//--------------------------------------------------------------------------
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LookingAheadCollectionViewCell", for: indexPath) as? LookingAheadCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.backgroundColor = UIColor(red: 79/255, green: 98/255, blue: 142/255, alpha: 0.35)
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.cornerRadius = 5.0
        cell.layer.borderWidth = 0.5
        
        let dataPoint = WeatherController.shared.weather
        let dataPointHourly = WeatherController.shared.weatherbitWeatherHourly
        
        if let hourTime = dataPointHourly?.data?[indexPath.row].timestampLocal {
//            let hourlyTime = NSDate(timeIntervalSince1970: (hourTime))
            
//            let dailyHourString = "\(hourlyTime)" // the date string to be parsed
            let df3 = DateFormatter()
            df3.locale = Locale(identifier: "en_US")
            df3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let hour = df3.date(from: hourTime) {
                let format = "ha"
                let df4 = DateFormatter()
                df4.dateFormat = format
                df4.amSymbol = "AM"
                df4.pmSymbol = "PM"
                let string = df4.string(from: hour)
                cell.lookingAheadHourLabel.text = string
            } else {
                print("Unable to parse date string")
            }
        }
        
        if let hourlyTemp = dataPointHourly?.data?[indexPath.row].appTemp {
            let newHighTemp = String(format: "%.0f", hourlyTemp)
            cell.lookingAheadTempLabel.text = newHighTemp + "\u{00B0}"
        }
        
        let conditionIcon = dataPointHourly?.data?[indexPath.row].weather?.icon
        switch conditionIcon {
        case "t01d", "t02d","t03d":
            cell.lookingAheadConditionImage.image = UIImage(named: "t01d")
        case "t01n","t02n", "t03n":
            cell.lookingAheadConditionImage.image = UIImage(named: "t01d")
        case "t04d","t05d":
            cell.lookingAheadConditionImage.image = UIImage(named: "t04d")
        case "t04n","t05n":
            cell.lookingAheadConditionImage.image = UIImage(named: "t04n")
        case "d01d","d02d", "d03d":
            cell.lookingAheadConditionImage.image = UIImage(named: "d01d")
        case "d01n","d02n", "d03n":
            cell.lookingAheadConditionImage.image = UIImage(named: "d01n")
        case "r01d","r02d", "r03d":
            cell.lookingAheadConditionImage.image = UIImage(named: "r01d")
        case "r01n","r02n", "r03n":
            cell.lookingAheadConditionImage.image = UIImage(named: "r01n")
        case "f01d","r04d","r05d","r06d":
            cell.lookingAheadConditionImage.image = UIImage(named: "f01d")
        case "f01n","r04n","r05n","r06n":
            cell.lookingAheadConditionImage.image = UIImage(named: "f01n")
        case "s01d","s02d","s03d","s04d","s05d":
            cell.lookingAheadConditionImage.image = UIImage(named: "s01d")
         case "s01n","s02n","s03n","s04n","s05n":
            cell.lookingAheadConditionImage.image = UIImage(named: "s01n")
         case "a01d","a02d","a03d","a04d","a05d", "a06d":
            cell.lookingAheadConditionImage.image = UIImage(named: "a01d")
        case "a01n","a02n","a03n","a04n","a05n", "a06n":
            cell.lookingAheadConditionImage.image = UIImage(named: "a01n")
        case "c01d":
            cell.lookingAheadConditionImage.image = UIImage(named: "c01d")
        case "c02d","c03d":
            cell.lookingAheadConditionImage.image = UIImage(named: "c02d")
        case "c04d":
            cell.lookingAheadConditionImage.image = UIImage(named: "c04d")
        case "c01n":
            cell.lookingAheadConditionImage.image = UIImage(named: "c01n")
        case "c02n","c03n":
            cell.lookingAheadConditionImage.image = UIImage(named: "c02n")
        case "c04n":
            cell.lookingAheadConditionImage.image = UIImage(named: "c04n")
        default:
            cell.lookingAheadConditionImage.image = UIImage(named: "c01d")
        }
        
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        
        if let precipChance = dataPointHourly?.data?[indexPath.row].precip {
            let precipFormatted = String(format: "%.2f", precipChance)
            let precipUnits: String
            if defaults.string(forKey: "Units") == "units=i" {
                precipUnits = "in"
            } else {
                precipUnits = "mm"
            }
            
            cell.lookingAheadPrecipLabel.text = "\(precipFormatted)\(precipUnits)"
        }
        
        return cell
    }
}
