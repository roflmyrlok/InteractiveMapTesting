//
//  ProfileViewModel.swift
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
}
