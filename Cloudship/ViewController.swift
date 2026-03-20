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
                Task{
                    do {
                        // Await the asynchronous function call
                        try await WeatherController.shared.fetchWeatherInfo(lat: latitude!, lon: longitude!, units: units!)
                    } catch {
                        // Handle the error
                        print("Error fetching weather info: \(error)")
                    }
                }
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
        
        let dataPointV4 = WeatherController.shared.climacellV4Weather
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
        // Legacy segue handling removed – radar is now in its own tab
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
            Task{
                do {
                    // Await the asynchronous function call
                    try await WeatherController.shared.fetchWeatherInfo(lat: location.coordinate.latitude, lon: location.coordinate.longitude, units: units!)
                } catch {
                    // Handle the error
                    print("Error fetching weather info: \(error)")
                }
            }
            
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
            
            Task{
                do {
                    // Await the asynchronous function call
                    try await WeatherController.shared.fetchWeatherInfo(lat: latitude, lon: longitude, units: units!)
                } catch {
                    // Handle the error
                    print("Error fetching weather info: \(error)")
                }
            }
            
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
        if tableView == currentlyTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CurrentlyTableViewCell", for: indexPath) as? CurrentlyTableViewCell else {
                return UITableViewCell() // Return a default cell if dequeue fails
            }
            
            // Hide alert view container initially
            cell.alertViewContainer.isHidden = true
            print("GIVE ME THE TEMPERATURE PLEASE 1st")
//            let weatherData = try await fetchCurrentWeather(lat: lat, lon: lon, units: units)
            print(WeatherController.shared.climacellV4Weather?.realtime?.values)
            print(WeatherController.shared.forecastWeather?.timelines?.hourly?.first?.values)
            // Access weather data
            guard let realtime = WeatherController.shared.climacellV4Weather?.realtime?.values.temperature else {
                            cell.currentTempLabel.text = "--"
                            return cell
                        }
            print("GIVE ME THE TEMPERATURE PLEASE 2nd")
            print(WeatherController.shared.climacellV4Weather?.realtime?.values.temperature)
            // Set current temperature
            if let forecastData = WeatherController.shared.climacellV4Weather?.realtime?.values,
               let currentWeather =  forecastData.temperature {
                        // Set current temperature
                let currentTemperature = forecastData.temperature
                let currentNewTemp = String(format: "%.0f", currentTemperature!)
                        cell.currentTempLabel.text = "\(currentNewTemp)°"
                    } else {
                        cell.currentTempLabel.text = "--"
                    }
            
            // Set alerts
            cell.alertViewContainer.isHidden = true
            
            // Style buttons
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
            
            return cell
        } else if tableView == searchTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableViewCell", for: indexPath) as? SearchTableViewCell else {
                return UITableViewCell() // Return a default cell if dequeue fails
            }
            if indexPath.row < matchingItems.count {
                let selectedItem = matchingItems[indexPath.row].placemark
                cell.searchTitleLabel?.text = selectedItem.name
                cell.searchDetailsLabel?.text = selectedItem.title
            } else {
                cell.searchTitleLabel.attributedText = homeLocationTitle
                cell.searchDetailsLabel.text = lastLocationString
            }
            return cell
        }
        
        // Default return value for safety
        return UITableViewCell()
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
            
            return cell
        }
    }

