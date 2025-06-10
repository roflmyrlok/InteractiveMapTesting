//
//  ChangePasswordRequest.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 09.06.2025.
//

import Foundation

struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
    let confirmNewPassword: String
}

struct DeleteAccountRequest: Codable {
    let currentPassword: String
}

struct PasswordChangeResponse: Codable {
    let message: String
}

// Helper struct for empty responses (HTTP 204 No Content)
struct EmptyResponse: Codable {
    // Empty struct for endpoints that return no content
    init() {}
}
