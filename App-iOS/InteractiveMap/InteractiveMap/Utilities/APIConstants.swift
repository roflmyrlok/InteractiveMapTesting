//
//  APIConstants.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

struct APIConstants {
    // Base URL for production server - now using a single port
    static let baseURL = "http://ec2-63-177-81-123.eu-central-1.compute.amazonaws.com"
    
    // Service endpoints with single entry point
    static let userServiceURL = "\(baseURL)/api/users"
    static let authServiceURL = "\(baseURL)/api/auth"
    static let locationServiceURL = "\(baseURL)/api/locations"
    static let reviewServiceURL = "\(baseURL)/api/reviews"
}
