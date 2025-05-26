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
    @Published var selectedLocation: Location?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationService = LocationService()
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
                    // For debugging
                    print("Received \(locations.count) locations")
                    
                    // Limit to maxLocations
                    let limitedLocations = Array(locations.prefix(self?.maxLocations ?? 10))
                    print("Displaying \(limitedLocations.count) locations (limited)")
                    
                    for location in limitedLocations {
                        print("Location: \(location.address) - lat: \(location.latitude), lon: \(location.longitude)")
                    }
                    
                    self?.locations = limitedLocations
                } else {
                    print("No locations returned and no error")
                }
            }
        }
    }
}
