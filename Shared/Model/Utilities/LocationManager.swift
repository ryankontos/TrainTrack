//
//  LocationManager.swift
//  TrainTrack
//
//  Created by Ryan Kontos on 19/11/20.
//

import Foundation
import MapKit
import CoreLocation
import os.log

private let logger = Logger(subsystem: "com.ryankontos.traintrack", category: "LocationManager")

final class LocationManager: NSObject, CLLocationManagerDelegate {

    static var shared: LocationManager?

    private(set) var currentLocation: CLLocation?
    private(set) var currentLocationName: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var isGeocoding = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func activate() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        }
    }

    func updateLocationName() {
        guard let location = currentLocation, !isGeocoding else { return }
        isGeocoding = true

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            defer { self?.isGeocoding = false }

            if let error {
                logger.error("Geocoding error: \(error.localizedDescription)")
                return
            }

            if let locality = placemarks?.first?.locality {
                self?.currentLocationName = locality
                logger.info("Location: \(locality)")
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        currentLocation = latest

        // Auto-update name if we don't have one yet
        if currentLocationName == nil {
            updateLocationName()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location update failed: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}

