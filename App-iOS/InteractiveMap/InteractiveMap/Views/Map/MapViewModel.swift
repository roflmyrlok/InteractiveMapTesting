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
                    for location in locations {
                        print("Location: \(location.name) - lat: \(location.latitude), lon: \(location.longitude)")
                    }
                    
                    self?.locations = locations
                } else {
                    print("No locations returned and no error")
                }
            }
        }
    }
}
