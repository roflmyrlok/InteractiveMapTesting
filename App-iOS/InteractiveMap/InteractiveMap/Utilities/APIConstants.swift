//
//  APIConstants.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import Foundation

struct APIConstants {
    static let baseURL = "http://localhost:5280"
    static let locationServiceURL = "http://localhost:5282/api/locations"
    static let reviewServiceURL = "http://localhost:5284/api/reviews"
    
    static let userServiceURL = "\(baseURL)/api/users"
    static let authServiceURL = "\(baseURL)/api/auth"
}
