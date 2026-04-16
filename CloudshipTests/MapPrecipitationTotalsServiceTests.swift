//
//  MapPrecipitationTotalsServiceTests.swift
//  CloudshipTests
//

import XCTest
import CoreLocation
@testable import Cloudship

final class MapPrecipitationTotalsServiceTests: XCTestCase {

    func testForecast24HourTotalSumsHourlyValues() async throws {
        let now = makeDate("2026-04-16T12:30:00-07:00")
        let service = makeService(
            now: now,
            responses: [
                forecastResponse(
                    timezone: "America/Los_Angeles",
                    times: [
                        "2026-04-16T12:00", "2026-04-16T13:00", "2026-04-16T14:00",
                        "2026-04-17T11:00", "2026-04-17T12:00", "2026-04-17T13:00"
                    ],
                    precipitation: [0.1, 0.2, 0.3, 0.4, 0.5, 9.9]
                )
            ]
        )

        let totals = try await service.fetchTotals(
            coordinate: CLLocationCoordinate2D(latitude: 34.05, longitude: -118.24),
            direction: .forecast,
            window: .hours24,
            units: "imperial"
        )

        XCTAssertEqual(totals.sampleCount, 4)
        XCTAssertEqual(totals.totalPrecipitation, 1.0, accuracy: 0.0001)
    }

    func testPast48HourTotalSumsAcrossDateBoundary() async throws {
        let now = makeDate("2026-04-16T12:30:00-07:00")
        let service = makeService(
            now: now,
            responses: [
                forecastResponse(
                    timezone: "America/Los_Angeles",
                    times: [
                        "2026-04-14T11:00", "2026-04-14T12:00", "2026-04-15T12:00",
                        "2026-04-16T11:00", "2026-04-16T12:00", "2026-04-16T13:00"
                    ],
                    precipitation: [9.0, 0.1, 0.2, 0.3, 0.4, 5.0]
                )
            ]
        )

        let totals = try await service.fetchTotals(
            coordinate: CLLocationCoordinate2D(latitude: 47.61, longitude: -122.33),
            direction: .past,
            window: .hours48,
            units: "metric"
        )

        XCTAssertEqual(totals.sampleCount, 4)
        XCTAssertEqual(totals.totalPrecipitation, 1.0, accuracy: 0.0001)
    }

    func testCachePreventsDuplicateFetchesForRoundedCoordinate() async throws {
        let now = makeDate("2026-04-16T12:30:00-07:00")
        var fetchCount = 0
        let payload = forecastResponse(
            timezone: "America/Los_Angeles",
            times: ["2026-04-16T13:00", "2026-04-16T14:00", "2026-04-16T15:00"],
            precipitation: [0.1, 0.2, 0.3]
        )
        let service = MapPrecipitationTotalsService(
            fetchData: { _ in
                fetchCount += 1
                return payload
            },
            nowProvider: { now }
        )

        _ = try await service.fetchTotals(
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            direction: .forecast,
            window: .hours24,
            units: "imperial"
        )
        _ = try await service.fetchTotals(
            coordinate: CLLocationCoordinate2D(latitude: 40.7131, longitude: -74.0059),
            direction: .forecast,
            window: .hours24,
            units: "imperial"
        )

        XCTAssertEqual(fetchCount, 1)
    }

    // MARK: - Helpers

    private func makeService(now: Date, responses: [Data]) -> MapPrecipitationTotalsService {
        var queue = responses
        return MapPrecipitationTotalsService(
            fetchData: { _ in
                guard !queue.isEmpty else {
                    throw MapPrecipitationTotalsError.unavailable
                }
                return queue.removeFirst()
            },
            nowProvider: { now }
        )
    }

    private func forecastResponse(timezone: String, times: [String], precipitation: [Double]) -> Data {
        let object: [String: Any] = [
            "timezone": timezone,
            "hourly": [
                "time": times,
                "precipitation": precipitation
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: object)
    }

    private func makeDate(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)!
    }
}
