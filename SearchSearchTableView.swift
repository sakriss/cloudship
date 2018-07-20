//
//  SearchSearchTableView.swift
//  Cloudship
//
//  Created by Scott Kriss on 7/9/18.
//  Copyright © 2018 Scott Kriss. All rights reserved.
//

import UIKit
import MapKit

class SearchSearchTableView: UITableViewController {
    var matchingItems:[MKMapItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
}

extension SearchSearchTableView : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
        let searchRequest = MKLocalSearchRequest()
        //searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start { (response, error) in
            if response == nil {
                print("Error gathering new location")
            }else {
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
//                WeatherController.shared.fetchWeatherInfo(latitude: latitude!, longitude: longitude!)
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
                self.matchingItems = (response?.mapItems)!
//                self.searchTableView.reloadData()
            }

        }
    }
}

extension SearchSearchTableView {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
//        cell.detailTextLabel?.text = parseAddress(selectedItem)
        return cell
    }
}
