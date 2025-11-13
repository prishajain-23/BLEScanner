//
//  LocationService.swift
//  BLEScanner
//
//  Handles location tracking for emergency messages
//

import Foundation
import CoreLocation

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationString: String = "Location unavailable"

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Request Permissions

    func requestPermissions() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ Location permissions already granted")
        case .denied, .restricted:
            print("⚠️ Location permissions denied or restricted")
        @unknown default:
            break
        }
    }

    // MARK: - Get Current Location

    func getCurrentLocation() async -> String {
        // Request location update
        locationManager.requestLocation()

        // Wait a moment for location to update
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        if let location = currentLocation {
            return await formatLocation(location)
        } else {
            return "Location unavailable"
        }
    }

    // MARK: - Format Location

    private func formatLocation(_ location: CLLocation) async -> String {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        // Format coordinates with 6 decimal places (approx 0.1m accuracy)
        let latString = String(format: "%.6f", latitude)
        let lonString = String(format: "%.6f", longitude)

        // Create Google Maps link
        let mapsLink = "https://maps.google.com/?q=\(latString),\(lonString)"

        // Try to reverse geocode to get human-readable location
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                var locationParts: [String] = []

                // Add locality (city/town)
                if let locality = placemark.locality {
                    locationParts.append(locality)
                }

                // Add state
                if let state = placemark.administrativeArea {
                    locationParts.append(state)
                }

                if !locationParts.isEmpty {
                    let readableLocation = locationParts.joined(separator: ", ")
                    return "\(readableLocation) - \(mapsLink)"
                }
            }
        } catch {
            print("⚠️ Reverse geocoding failed: \(error.localizedDescription)")
        }

        // Fallback to coordinates if geocoding fails
        return "Lat: \(latString), Lon: \(lonString) - \(mapsLink)"
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                self.currentLocation = location
                self.locationString = await self.formatLocation(location)
                print("📍 Location updated: \(self.locationString)")
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location error: \(error.localizedDescription)")
            self.locationString = "Location unavailable"
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            print("📍 Location authorization: \(self.authorizationStatus.rawValue)")

            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}
