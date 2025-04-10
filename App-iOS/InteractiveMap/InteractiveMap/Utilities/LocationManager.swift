// App-iOS/InteractiveMap/InteractiveMap/Utilities/LocationManager.swift

import Foundation
import CoreLocation
import MapKit
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var region = MKCoordinateRegion(
        // Default to Kyiv
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Add this flag to control when region updates happen
    private var shouldUpdateRegion = true
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        
        // Only update region if flag is true
        if shouldUpdateRegion {
            updateRegion(location: location)
            // Disable further automatic updates until explicitly requested
            shouldUpdateRegion = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Request only a single location update instead of continuous updates
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func updateRegion(location: CLLocation) {
        DispatchQueue.main.async {
            self.shouldUpdateRegion = true // Reset the flag for next explicit update
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    // Add this method to disable auto-centering
    func stopUpdatingRegion() {
        shouldUpdateRegion = false
    }
    
    // Add this method to enable manual user interaction with the map
    func userInteractionBegan() {
        shouldUpdateRegion = false
        locationManager.stopUpdatingLocation()
    }
}
