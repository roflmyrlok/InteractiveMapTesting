//
//  APIConstants.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import Foundation

struct APIConstants {
    static let baseURL = "http://ec2-3-122-118-9.eu-central-1.compute.amazonaws.com"
    static let locationServiceURL = "http://ec2-3-122-118-9.eu-central-1.compute.amazonaws.com:5282/api/locations"
    static let reviewServiceURL = "http://ec2-3-122-118-9.eu-central-1.compute.amazonaws.com:5284/api/reviews"
    
    static let userServiceURL = "\(baseURL)/api/users"
    static let authServiceURL = "\(baseURL)/api/auth"
}

import Foundation

struct APIConfig {
    // Base URL for EC2 instance
    static let baseURL = "http://ec2-3-122-118-9.eu-central-1.compute.amazonaws.com"
    
    // Service endpoints
    struct UserService {
        static let base = "\(APIConfig.baseURL):5280/api"
        static let login = "\(base)/auth/login"
        static let register = "\(base)/users"
        static let profile = "\(base)/users"
    }
    
    struct LocationService {
        static let base = "\(APIConfig.baseURL):5282/api"
        static let locations = "\(base)/locations"
        static let nearby = "\(base)/locations/nearby"
        static let byProperty = "\(base)/locations/by-property"
    }
    
    struct ReviewService {
        static let base = "\(APIConfig.baseURL):5284/api"
        static let reviews = "\(base)/reviews"
        static let byLocation = "\(base)/reviews/by-location"
        static let averageRating = "\(base)/reviews/average-rating"
    }
    
    static let tokenStorageKey = "auth_token"
}
