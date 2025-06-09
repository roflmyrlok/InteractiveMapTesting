//
//  TokenManager.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import Foundation
import KeychainSwift

class TokenManager {
    static let shared = TokenManager()
    
    private let keychain = KeychainSwift()
    private let tokenKey = "auth_token"
    
    func saveToken(_ token: String) {
        keychain.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return keychain.get(tokenKey)
    }
    
    func clearToken() {
        keychain.delete(tokenKey)
    }
    
    var isAuthenticated: Bool {
        return getToken() != nil
    }
}