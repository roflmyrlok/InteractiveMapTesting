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
}

struct CreateReviewRequest: Codable {
    let locationId: String
    let rating: Int
    let content: String
}
