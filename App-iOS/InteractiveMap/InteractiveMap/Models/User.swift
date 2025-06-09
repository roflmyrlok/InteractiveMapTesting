//
//  User.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let role: Int
    let createdAt: String
    let lastLoginDate: String?
    
    // Computed properties for better display
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    var roleDisplayName: String {
        switch role {
        case 0:
            return "Member"
        case 1:
            return "Administrator"
        case 2:
            return "Super Admin"
        default:
            return "Unknown"
        }
    }
}
