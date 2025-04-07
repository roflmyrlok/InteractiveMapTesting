//
//  LocationService.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


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
                completion(locations, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    func getNearbyLocations(latitude: Double, longitude: Double, radiusKm: Double = 10, completion: @escaping ([Location]?, Error?) -> Void) {
        let url = "\(APIConstants.locationServiceURL)/nearby?latitude=\(latitude)&longitude=\(longitude)&radiusKm=\(radiusKm)"
        
        NetworkManager.shared.request(
            url,
            method: .get
        ) { (result: Result<[Location], Error>) in
            switch result {
            case .success(let locations):
                completion(locations, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
