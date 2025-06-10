//
//  InstantFeedbackModels.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 10.06.2025.
//

import Foundation

enum InstantFeedbackType: Int, CaseIterable, Codable {
    case allGood = 0
    case problemInside = 1
    case cantGetIn = 2
    
    var title: String {
        switch self {
        case .allGood:
            return "All Good"
        case .problemInside:
            return "Problem Inside"
        case .cantGetIn:
            return "Can't Get In"
        }
    }
    
    var description: String {
        switch self {
        case .allGood:
            return "Shelter is open and functioning normally"
        case .problemInside:
            return "Shelter is open but has issues inside"
        case .cantGetIn:
            return "Cannot access or enter the shelter"
        }
    }
    
    var icon: String {
        switch self {
        case .allGood:
            return "checkmark.circle.fill"
        case .problemInside:
            return "exclamationmark.triangle.fill"
        case .cantGetIn:
            return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .allGood:
            return "green"
        case .problemInside:
            return "yellow"
        case .cantGetIn:
            return "red"
        }
    }
}

struct SubmitInstantFeedbackRequest: Codable {
    let locationId: String
    let feedbackType: InstantFeedbackType
}

struct InstantFeedbackResponse: Codable {
    let message: String
}

struct LocationInstantStatus: Codable {
    let locationId: String
    let colorCode: String
    let allGoodCount: Int
    let problemInsideCount: Int
    let cantGetInCount: Int
    let lastUpdated: String
    let dominantStatus: InstantFeedbackType
}

struct LocationInstantStatusSummary: Codable {
    let locationId: String
    let colorCode: String
}

struct GetLocationInstantStatusesRequest: Codable {
    let locationIds: [String]
}
