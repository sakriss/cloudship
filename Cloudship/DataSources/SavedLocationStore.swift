//
//  SavedLocationStore.swift
//  Cloudship
//
//  Codable store for saved locations with per-location notification preferences.
//  Persisted in UserDefaults under "savedLocations_v1".
//

import Foundation

struct SavedLocation: Codable, Equatable {
    var name: String
    var lat: Double
    var lon: Double
    var rainAlertsEnabled: Bool
    var dailySummaryEnabled: Bool
    var dailySummaryHour: Int  // 0–23, default 7

    /// Unique key for per-location notification state tracking.
    var locationKey: String {
        "\(String(format: "%.4f", lat)),\(String(format: "%.4f", lon))"
    }

    init(name: String, lat: Double, lon: Double,
         rainAlertsEnabled: Bool = false,
         dailySummaryEnabled: Bool = false,
         dailySummaryHour: Int = 7) {
        self.name = name
        self.lat = lat
        self.lon = lon
        self.rainAlertsEnabled = rainAlertsEnabled
        self.dailySummaryEnabled = dailySummaryEnabled
        self.dailySummaryHour = dailySummaryHour
    }
}

class SavedLocationStore {

    static let shared = SavedLocationStore()
    private init() {}

    private let key = "savedLocations_v1"
    private let maxLocations = 10

    // MARK: - Read

    var locations: [SavedLocation] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([SavedLocation].self, from: data)) ?? []
    }

    // MARK: - Write

    @discardableResult
    func add(_ location: SavedLocation) -> Bool {
        var list = locations
        guard list.count < maxLocations else { return false }
        // Avoid duplicates by lat/lon
        guard !list.contains(where: { $0.locationKey == location.locationKey }) else { return false }
        list.append(location)
        save(list)
        return true
    }

    func remove(at index: Int) {
        var list = locations
        guard list.indices.contains(index) else { return }
        list.remove(at: index)
        save(list)
    }

    func update(at index: Int, _ location: SavedLocation) {
        var list = locations
        guard list.indices.contains(index) else { return }
        list[index] = location
        save(list)
    }

    /// All locations that have rain alerts enabled (max 5 for background checks).
    func allWithRainAlerts() -> [SavedLocation] {
        Array(locations.filter(\.rainAlertsEnabled).prefix(5))
    }

    // MARK: - Private

    private func save(_ list: [SavedLocation]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
