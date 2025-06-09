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
        
        do {
            id = try container.decode(String.self, forKey: .id)
            latitude = try container.decode(Double.self, forKey: .latitude)
            longitude = try container.decode(Double.self, forKey: .longitude)
            address = try container.decode(String.self, forKey: .address)
            createdAt = try container.decode(String.self, forKey: .createdAt)
            updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            details = try container.decode([LocationDetail].self, forKey: .details)
            
            // Debug logging for potential issues
            if id.isEmpty {
                print("WARNING: Location decoded with empty ID")
            }
            if address.isEmpty {
                print("WARNING: Location decoded with empty address")
            }
            if latitude == 0 && longitude == 0 {
                print("WARNING: Location decoded with zero coordinates")
            }
            
        } catch {
            print("ERROR decoding Location: \(error)")
            print("Container keys available: \(container.allKeys)")
            throw error
        }
    }
}

// Add Equatable conformance for better debugging
extension Location: Equatable {
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id
    }
}

// Add Hashable for better performance in collections
extension Location: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
