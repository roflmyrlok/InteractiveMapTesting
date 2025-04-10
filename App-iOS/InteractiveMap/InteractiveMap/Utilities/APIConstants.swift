//
//  APIConstants.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

struct APIConstants {
    // Base URL for EC2 instance
    static let baseURL = "http://ec2-3-122-118-9.eu-central-1.compute.amazonaws.com"
    
    // Service endpoints with proper ports
    static let userServiceURL = "\(baseURL):5280/api/users"
    static let authServiceURL = "\(baseURL):5280/api/auth"
    static let locationServiceURL = "\(baseURL):5282/api/locations"
    static let reviewServiceURL = "\(baseURL):5284/api/reviews"
}
