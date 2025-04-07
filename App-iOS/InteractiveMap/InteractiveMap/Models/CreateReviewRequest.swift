//
//  CreateReviewRequest.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


struct CreateReviewRequest: Codable {
    let locationId: String
    let rating: Int
    let content: String
}
