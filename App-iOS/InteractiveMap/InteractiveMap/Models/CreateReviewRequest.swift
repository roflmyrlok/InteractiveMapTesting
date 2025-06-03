//
//  CreateReviewRequest.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

struct CreateReviewRequest: Codable {
    let locationId: String
    let rating: Int
    let content: String
}

// For multipart form data with images
struct CreateReviewWithImagesRequest {
    let locationId: String
    let rating: Int
    let content: String
    let images: [Data]
    let imageNames: [String]
}
