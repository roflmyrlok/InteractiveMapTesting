// Services/LocationService.swift
import Foundation
import Alamofire

class LocationService {
    private let cacheManager = CacheManager.shared
    
    func getLocations(completion: @escaping ([Location]?, Error?) -> Void) {
        // Try cache first
        let cachedLocations = cacheManager.getCachedLocations()
        if !cachedLocations.isEmpty {
            print("Returning \(cachedLocations.count) locations from cache")
            completion(cachedLocations, nil)
            
            // Still fetch from network in background to update cache
            fetchLocationsFromNetwork { [weak self] locations, error in
                if let locations = locations {
                    // Update cache with fresh data
                    for location in locations {
                        self?.cacheManager.cacheLocation(location)
                    }
                }
            }
            return
        }
        
        // Fetch from network
        fetchLocationsFromNetwork { [weak self] locations, error in
            if let locations = locations {
                print("Successfully fetched \(locations.count) locations from network")
                
                // Cache the locations
                for location in locations {
                    self?.cacheManager.cacheLocation(location)
                }
                
                completion(locations, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    private func fetchLocationsFromNetwork(completion: @escaping ([Location]?, Error?) -> Void) {
        NetworkManager.shared.request(
            APIConstants.locationServiceURL,
            method: .get
        ) { (result: Result<[Location], Error>) in
            switch result {
            case .success(let locations):
                completion(locations, nil)
            case .failure(let error):
                print("LocationService error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func getLocation(id: String, completion: @escaping (Location?, Error?) -> Void) {
        // Try cache first
        if let cachedLocation = cacheManager.getCachedLocation(id: id) {
            print("Returning location \(id) from cache")
            completion(cachedLocation, nil)
            
            // Still fetch from network in background to update cache
            fetchLocationFromNetwork(id: id) { [weak self] location, error in
                if let location = location {
                    self?.cacheManager.cacheLocation(location)
                }
            }
            return
        }
        
        // Fetch from network
        fetchLocationFromNetwork(id: id) { [weak self] location, error in
            if let location = location {
                print("Successfully fetched location \(id) from network")
                self?.cacheManager.cacheLocation(location)
                completion(location, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    private func fetchLocationFromNetwork(id: String, completion: @escaping (Location?, Error?) -> Void) {
        let url = "\(APIConstants.locationServiceURL)/\(id)"
        
        NetworkManager.shared.request(
            url,
            method: .get
        ) { (result: Result<Location, Error>) in
            switch result {
            case .success(let location):
                completion(location, nil)
            case .failure(let error):
                print("LocationService error for ID \(id): \(error)")
                completion(nil, error)
            }
        }
    }
    
    func getNearbyLocations(latitude: Double, longitude: Double, radiusKm: Double = 1, completion: @escaping ([Location]?, Error?) -> Void) {
        let url = "\(APIConstants.locationServiceURL)/nearby?latitude=\(latitude)&longitude=\(longitude)&radiusKm=\(radiusKm)"
        
        print("Requesting nearby locations from: \(url)")
        
        NetworkManager.shared.request(
            url,
            method: .get
        ) { (result: Result<[Location], Error>) in
            switch result {
            case .success(let locations):
                print("Successfully decoded \(locations.count) nearby locations")
                
                // Cache the nearby locations
                for location in locations {
                    CacheManager.shared.cacheLocation(location)
                }
                
                completion(locations, nil)
            case .failure(let error):
                print("LocationService nearby error: \(error)")
                
                // If network fails, try to return cached locations within radius
                let cachedLocations = CacheManager.shared.getCachedLocations()
                let nearbyCache = cachedLocations.filter { location in
                    let distance = self.calculateDistance(
                        lat1: latitude, lon1: longitude,
                        lat2: location.latitude, lon2: location.longitude
                    )
                    return distance <= radiusKm
                }
                
                if !nearbyCache.isEmpty {
                    print("Returning \(nearbyCache.count) nearby locations from cache due to network error")
                    completion(nearbyCache, nil)
                } else {
                    completion(nil, error)
                }
            }
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
    
    // MARK: - Cache Management
    
    func getCachedLocations() -> [Location] {
        return cacheManager.getCachedLocations()
    }
    
    func getLastViewedLocations() -> [Location] {
        return cacheManager.getLastViewedLocationObjects()
    }
    
    func isLocationCached(_ locationId: String) -> Bool {
        return cacheManager.isLocationCached(locationId)
    }
}
