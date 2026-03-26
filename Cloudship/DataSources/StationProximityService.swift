//
//  StationProximityService.swift
//  Cloudship
//
//  Queries NOAA's /points/ and /observationStations endpoints to find the
//  distance from the user's location to the nearest active NWS observation
//  station. Returns nil for non-US locations (NOAA 404).
//

import Foundation
import CoreLocation

actor StationProximityService {

    static let shared = StationProximityService()
    private init() {}

    struct Result {
        let stationID: String
        let stationName: String?
        let distanceKm: Double
    }

    private let userAgent = "Cloudship iOS App (contact@cloudshipapp.com)"

    // MARK: - Public

    /// Returns the nearest NOAA observation station for a US coordinate, or nil
    /// if the location is outside the US or the request fails.
    func nearestNOAAStation(lat: Double, lon: Double) async -> Result? {
        guard let stationsURL = await fetchStationsURL(lat: lat, lon: lon) else { return nil }
        return await fetchNearestStation(from: stationsURL, userLat: lat, userLon: lon)
    }

    // MARK: - Private

    private func fetchStationsURL(lat: Double, lon: Double) async -> String? {
        let latStr = String(format: "%.4f", lat)
        let lonStr = String(format: "%.4f", lon)
        guard let url = URL(string: "https://api.weather.gov/points/\(latStr),\(lonStr)") else { return nil }

        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(NOAAPointsResponse.self, from: data)
            return decoded.properties?.observationStations
        } catch {
            return nil
        }
    }

    private func fetchNearestStation(from urlString: String, userLat: Double, userLon: Double) async -> Result? {
        guard let url = URL(string: urlString) else { return nil }

        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let stations = try JSONDecoder().decode(NOAAStationsResponse.self, from: data)

            guard let firstFeature = stations.features?.first,
                  let stationID = firstFeature.properties?.stationIdentifier,
                  let coords = firstFeature.geometry?.coordinates,
                  coords.count >= 2 else { return nil }

            // GeoJSON coordinates are [longitude, latitude]
            let stationLon = coords[0]
            let stationLat = coords[1]

            let userLocation    = CLLocation(latitude: userLat, longitude: userLon)
            let stationLocation = CLLocation(latitude: stationLat, longitude: stationLon)
            let distanceKm = userLocation.distance(from: stationLocation) / 1000.0

            return Result(
                stationID:   stationID,
                stationName: firstFeature.properties?.name,
                distanceKm:  distanceKm
            )
        } catch {
            return nil
        }
    }
}

