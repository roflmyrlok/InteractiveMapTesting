//
//  LocationViewModel.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//
import Foundation
import MapKit

class LocationViewModel: ObservableObject {
    @Published var location: Location?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    private let locationService = LocationService()
    
    func loadLocation(id: String) {
        isLoading = true
        errorMessage = nil
        
        locationService.getLocation(id: id) { [weak self] (location: Location?, error: Error?) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let location = location {
                    self?.location = location
                    self?.updateRegion(location: location)
                }
            }
        }
    }
    
    private func updateRegion(location: Location) {
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}
