//
//  Location.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

struct Location: Codable, Identifiable {
    let id: String
    let latitude: Double
    let longitude: Double
    let address: String
    let createdAt: String
    let updatedAt: String?
    let details: [LocationDetail]
    
    private enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, address, createdAt, updatedAt, details
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        address = try container.decode(String.self, forKey: .address)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        details = try container.decode([LocationDetail].self, forKey: .details)
    }
}
