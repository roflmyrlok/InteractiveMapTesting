//
//  User.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    var role: Int
    let createdAt: Date
    let lastLoginDate: Date?
}
