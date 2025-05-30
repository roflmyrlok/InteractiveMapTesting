// Services/LocationService.swift
import Foundation
import Alamofire

class LocationService {
    func getLocations(completion: @escaping ([Location]?, Error?) -> Void) {
        NetworkManager.shared.request(
            APIConstants.locationServiceURL,
            method: .get
        ) { (result: Result<[Location], Error>) in
            switch result {
            case .success(let locations):
                print("Successfully decoded \(locations.count) locations")
                completion(locations, nil)
            case .failure(let error):
                print("LocationService error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func getLocation(id: String, completion: @escaping (Location?, Error?) -> Void) {
        let url = "\(APIConstants.locationServiceURL)/\(id)"
        
        NetworkManager.shared.request(
            url,
            method: .get
        ) { (result: Result<Location, Error>) in
            switch result {
            case .success(let location):
                print("Successfully decoded location: \(location.address)")
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
                completion(locations, nil)
            case .failure(let error):
                print("LocationService nearby error: \(error)")
                completion(nil, error)
            }
        }
    }
}
