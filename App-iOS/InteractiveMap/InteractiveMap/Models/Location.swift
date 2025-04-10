//
//  Location.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

struct Location: Codable, Identifiable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String
    let city: String
    let state: String
    let country: String
    let postalCode: String
    let createdAt: String
    let details: [LocationDetail]
}
