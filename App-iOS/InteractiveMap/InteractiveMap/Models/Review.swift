//
//  Review.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation
struct Review: Codable, Identifiable {
    let id: String
    let userId: String
    let locationId: String
    let rating: Int
    let content: String
    let createdAt: Date
    let updatedAt: Date?
    // Add this to the Review.swift file
    private enum CodingKeys: String, CodingKey {
        case id, userId, locationId, rating, content, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        locationId = try container.decode(String.self, forKey: .locationId)
        rating = try container.decode(Int.self, forKey: .rating)
        content = try container.decode(String.self, forKey: .content)
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
}

