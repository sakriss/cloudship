//
//  RadarViewController.swift
//  Cloudship
//
//  Created by Scott Kriss on 9/28/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AerisMapKit

class RadarViewController: UIViewController {
    
    var weatherMap: AWFWeatherMap!
    var legendView: AWFLegendView!
    var timelineView: AWFTimelineView!
    let layer = AWFRasterMapLayer(layerType: .radar)
    var userLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the weather map config
        let config = AWFWeatherMapConfig()
        // make any changes to your configuration before creating the weather map instance...
        
        // create the weather map instance
        weatherMap = AWFWeatherMap(mapType: .apple, config: config)
        weatherMap.addSource(forLayerType: .radar)
        weatherMap.delegate = self
        
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
//        weatherMap.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
//        weatherMap
        view.addSubview(weatherMap.weatherMapView)
        
        legendView = AWFLegendView(frame: CGRect(x: 0, y: (self.navigationController?.navigationBar.frame.size.height)! + 10, width: view.frame.width, height: 80))
        legendView.addLegend(forLayerType: .radar)
        legendView.showsCloseIndicator = false
        legendView.delegate = self as? AWFLegendViewDelegate
        view.addSubview(legendView)
        
        timelineView = AWFTimelineView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50.0))
        timelineView.delegate = self
        timelineView.startDate = weatherMap.timeline.fromTime
        timelineView.endDate = weatherMap.timeline.toTime
        timelineView.currentTime = weatherMap.timeline.fromTime
        view.addSubview(timelineView)
        
        // layout the map view container
        weatherMap.weatherMapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([weatherMap.weatherMapView.topAnchor.constraint(equalTo: view.topAnchor),
                                     weatherMap.weatherMapView.leftAnchor.constraint(equalTo: view.leftAnchor),
                                     weatherMap.weatherMapView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                     weatherMap.weatherMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        // layout the timeline view
        let timelineHeight: CGFloat = 50.0
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        timelineView.preservesSuperviewLayoutMargins = true
        NSLayoutConstraint.activate([timelineView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -timelineHeight),
                                     timelineView.leftAnchor.constraint(equalTo: view.leftAnchor),
                                     timelineView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                     timelineView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        
        // add an action handler for the timeline view's playback control
        timelineView.playButton.addTarget(self, action: #selector(toggleAnimation(sender:)), for: .touchUpInside)
        
        // start the weather map at the current time
        weatherMap.go(toTime: Date())
    }
    
    // MARK: Control Handlers
    
    @objc func toggleAnimation(sender: Any) {
        if let btn = sender as? UIButton {
            if weatherMap.isAnimating || weatherMap.isLoadingAnimation {
                btn.isSelected = false
                weatherMap.stopAnimating()
            } else {
                btn.isSelected = true
                weatherMap.startAnimating()
            }
        }
    }
}

// Observe change events on the timelineView so the weather map can be updated accordingly, such as when the user pans
// the timeline or taps the "Now" control to go to the current time/date.
extension RadarViewController: AWFTimelineViewDelegate {
    
    func timelineView(_ timelineView: AWFTimelineView!, didPanTo date: Date!) {
        if weatherMap.config.timelineScrubbingEnabled {
            weatherMap.pauseAnimation()
            weatherMap.go(toTime: date)
        }
    }
    
    func timelineView(_ timelineView: AWFTimelineView!, didSelect date: Date!) {
        weatherMap.stopAnimating()
        weatherMap.go(toTime: date)
    }
}

// Updates to the timelineView are handled by handling several AWFWeatherMapDelegate methods that notify our controller about changes to the weather map's
// timeline, such as start/end date changes and when the map begins or stops animating.
extension RadarViewController: AWFWeatherMapDelegate {
    
    func weatherMap(_ weatherMap: AWFWeatherMap, didUpdateTimelineRangeFrom fromDate: Date, to toDate: Date) {
        timelineView.startDate = fromDate
        timelineView.endDate = toDate
        timelineView.currentTime = weatherMap.timeline.currentTime
    }
    
    func weatherMapDidStartAnimating(_ weatherMap: AWFWeatherMap) {
        timelineView.playButton.isSelected = true
    }
    
    func weatherMapDidStopAnimating(_ weatherMap: AWFWeatherMap) {
        timelineView.playButton.isSelected = false
    }
    
    func weatherMapDidResetAnimation(_ weatherMap: AWFWeatherMap) {
        timelineView.setProgress(0, animated: true)
    }
    
    func weatherMap(_ weatherMap: AWFWeatherMap, animationDidUpdateTo date: Date) {
        timelineView.currentTime = date
    }
    
    func weatherMapDidStartLoadingAnimationData(_ weatherMap: AWFWeatherMap) {
        timelineView.playButton.isSelected = true
        timelineView.showLoading(true)
    }
    
    func weatherMapDidFinishLoadingAnimationData(_ weatherMap: AWFWeatherMap) {
        timelineView.setProgress(1.0, animated: true)
        timelineView.showLoading(false)
    }
    
    func weatherMapDidCancelLoadingAnimationData(_ weatherMap: AWFWeatherMap) {
        timelineView.playButton.isSelected = false
        timelineView.setProgress(0, animated: true)
        timelineView.showLoading(false)
    }
    
    func weatherMap(_ weatherMap: AWFWeatherMap, didUpdateAnimationDataLoadingProgress totalLoaded: Int, total: Int) {
        timelineView.setProgress(CGFloat(totalLoaded) / CGFloat(total), animated: true)
    }
    
    func weatherMap(_ weatherMap: AWFWeatherMap, didAddLayerForType layerType: AWFMapLayer) {
        guard let radarLayer = weatherMap.amp.rasterLayer(forLayerType: .radar) else { return }
        if AWFWeatherLayer.isAmp(layerType) {
            weatherMap.amp.bringRasterLayer(toTop: radarLayer)
        }
        weatherMap.amp.tileLayer.alpha = 0.5

        legendView.addLegend(forLayerType: .radar)
    }
    
    func weatherMap(_ weatherMap: AWFWeatherMap, didRemoveLayerForType layerType: AWFMapLayer) {
        legendView.removeLegend(forLayerType: .radar)
    }
    
    
//    let mapView = MKMapView()
//    let locationManager = CLLocationManager()
//    var userLocation = CLLocation()
//    let radarAPIKey = "17e182c3ab5751f199d94e19c685ca11"
//    let radarBaseURL = "https://tile.openweathermap.org/map/precipitation/10/"
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        locationManager.startUpdatingLocation()
////        locationManager.requestLocation()
//
//        buildRadarURL(radarBaseURL: radarBaseURL, radarAPIKey: radarAPIKey, userLocation: userLocation)
//
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//
//        mapView.translatesAutoresizingMaskIntoConstraints = false
//        mapView.delegate = self as? MKMapViewDelegate
//
//        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
//        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
//
//        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
//
//        view.addSubview(mapView)
//
//        let safeArea = view.safeAreaLayoutGuide
//
//        mapView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
//        mapView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor).isActive = true
//        mapView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor).isActive = true
//        mapView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor).isActive = true
//    }
//
//    func buildRadarURL(radarBaseURL: String,radarAPIKey: String,userLocation: CLLocation) -> String {
//        var radarURLString: String = ""
//        let userLat = userLocation.coordinate.latitude
//        let userLong = userLocation.coordinate.longitude
//        let userCoords = ("\(userLat)/\(userLong)")
//
//        radarURLString.append(radarBaseURL)
//        radarURLString.append(userCoords)
//        radarURLString.append(".png")
//        radarURLString.append("?appid=")
//        radarURLString.append(radarAPIKey)
//        print(radarURLString)
//        return radarURLString
//    }
//
//}
//
//extension RadarViewController: CLLocationManagerDelegate {
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        if status == .authorizedWhenInUse || status == .authorizedAlways {
//            manager.requestLocation()
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        mapView.showsUserLocation = true
//
//        for location in locations {
//            print("\(location.coordinate.latitude), \(location.coordinate.longitude)")
//            userLocation = location
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print(error)
//    }
}
