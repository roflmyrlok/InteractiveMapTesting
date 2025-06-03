//
//  MapViewModel.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation
import MapKit
import Combine

class MapViewModel: ObservableObject {
    @Published var locations: [Location] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationService = LocationService()
    private let cacheManager = CacheManager.shared
    private let maxLocations = 10
    
    func loadNearbyLocations(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil
        
        // For debugging
        print("Requesting locations near lat: \(latitude), lon: \(longitude)")
        
        locationService.getNearbyLocations(latitude: latitude, longitude: longitude) { [weak self] locations, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("Error loading locations: \(error.localizedDescription)")
                } else if let locations = locations {
                    // Enhanced debugging
                    print("Received \(locations.count) locations")
                    
                    // Check for data integrity issues
                    for (index, location) in locations.enumerated() {
                        print("Location \(index): ID=\(location.id), Address=\(location.address)")
                        print("  - Coordinates: lat=\(location.latitude), lon=\(location.longitude)")
                        print("  - Details count: \(location.details.count)")
                        
                        // Check for potential issues
                        if location.id.isEmpty {
                            print("  - WARNING: Empty ID detected!")
                        }
                        if location.address.isEmpty {
                            print("  - WARNING: Empty address detected!")
                        }
                        if location.latitude == 0 && location.longitude == 0 {
                            print("  - WARNING: Zero coordinates detected!")
                        }
                        
                        // Cache each location as it appears in the result set
                        // This caches locations that appear on screen (in map/list)
                        self?.cacheManager.cacheLocation(location)
                    }
                    
                    // Limit to maxLocations
                    let limitedLocations = Array(locations.prefix(self?.maxLocations ?? 10))
                    print("Displaying \(limitedLocations.count) locations (limited)")
                    
                    self?.locations = limitedLocations
                } else {
                    print("No locations returned and no error")
                }
            }
        }
    }
    
    func refreshLocations(latitude: Double, longitude: Double) {
        // Force refresh from network
        loadNearbyLocations(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Cache Management
    
    func getCachedLocations() -> [Location] {
        return cacheManager.getCachedLocations()
    }
    
    func loadCachedLocationsIfAvailable(near coordinate: CLLocationCoordinate2D, radius: Double = 1.0) {
        let cachedLocations = cacheManager.getCachedLocations()
        
        // Filter cached locations within radius
        let nearbyCache = cachedLocations.filter { location in
            let distance = calculateDistance(
                lat1: coordinate.latitude, lon1: coordinate.longitude,
                lat2: location.latitude, lon2: location.longitude
            )
            return distance <= radius
        }
        
        if !nearbyCache.isEmpty {
            print("Found \(nearbyCache.count) cached locations nearby")
            let limitedLocations = Array(nearbyCache.prefix(maxLocations))
            self.locations = limitedLocations
        }
    }
    
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371.0 // km
        
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
}
