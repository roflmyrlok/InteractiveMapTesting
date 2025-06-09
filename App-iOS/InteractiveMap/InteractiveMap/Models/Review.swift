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
    let imageUrls: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, locationId, rating, content, createdAt, updatedAt, imageUrls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        locationId = try container.decode(String.self, forKey: .locationId)
        rating = try container.decode(Int.self, forKey: .rating)
        content = try container.decode(String.self, forKey: .content)
        imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        // Multiple date formatters to handle different backend date formats
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }()
        ]
        
        // Try parsing createdAt with multiple formatters
        var parsedCreatedAt: Date?
        for formatter in formatters {
            if let date = formatter.date(from: createdAtString) {
                parsedCreatedAt = date
                break
            }
        }
        
        // Fallback to ISO8601DateFormatter
        if parsedCreatedAt == nil {
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            parsedCreatedAt = iso8601Formatter.date(from: createdAtString)
        }
        
        createdAt = parsedCreatedAt ?? Date()
        
        // Handle updatedAt with same logic
        if let updatedAtString = updatedAtString {
            var parsedUpdatedAt: Date?
            for formatter in formatters {
                if let date = formatter.date(from: updatedAtString) {
                    parsedUpdatedAt = date
                    break
                }
            }
            
            if parsedUpdatedAt == nil {
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                parsedUpdatedAt = iso8601Formatter.date(from: updatedAtString)
            }
            
            updatedAt = parsedUpdatedAt
        } else {
            updatedAt = nil
        }
        
        // Debug logging to help identify date parsing issues
        if parsedCreatedAt == nil {
            print("WARNING: Failed to parse createdAt date: \(createdAtString)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(rating, forKey: .rating)
        try container.encode(content, forKey: .content)
        try container.encode(imageUrls, forKey: .imageUrls)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        
        if let updatedAt = updatedAt {
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        } else {
            try container.encodeNil(forKey: .updatedAt)
        }
    }
}
