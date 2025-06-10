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
        print("DEBUG: Saving token: \(token.prefix(20))...")
        keychain.set(token, forKey: tokenKey)
        
        // Debug: Validate the token we just saved
        if let decodedToken = decodeJWT(token: token) {
            print("DEBUG: Token saved successfully. Expires at: \(Date(timeIntervalSince1970: decodedToken.exp))")
        } else {
            print("WARNING: Saved token could not be decoded!")
        }
    }
    
    func getToken() -> String? {
        guard let token = keychain.get(tokenKey) else {
            print("DEBUG: No token found in keychain")
            return nil
        }
        
        print("DEBUG: Retrieved token: \(token.prefix(20))...")
        
        // Check if token is expired
        if let decodedToken = decodeJWT(token: token) {
            let now = Date().timeIntervalSince1970
            if decodedToken.exp < now {
                print("WARNING: Token is expired, clearing it")
                clearToken()
                return nil
            } else {
                print("DEBUG: Token is valid for \(Int(decodedToken.exp - now)) more seconds")
                return token
            }
        } else {
            print("WARNING: Could not decode token, clearing it")
            clearToken()
            return nil
        }
    }
    
    func clearToken() {
        print("DEBUG: Clearing token from keychain")
        keychain.delete(tokenKey)
    }
    
    var isAuthenticated: Bool {
        let hasValidToken = getToken() != nil
        print("DEBUG: isAuthenticated check: \(hasValidToken)")
        return hasValidToken
    }
    
    // Helper function to decode JWT token for validation
    private func decodeJWT(token: String) -> JWTPayload? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            print("DEBUG: Invalid JWT format - expected 3 parts, got \(parts.count)")
            return nil
        }
        
        let payload = parts[1]
        var base64 = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64) else {
            print("DEBUG: Could not decode base64 payload")
            return nil
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("DEBUG: Payload is not a valid JSON object")
                return nil
            }
            
            print("DEBUG: JWT payload: \(json)")
            
            guard let exp = json["exp"] as? TimeInterval else {
                print("DEBUG: No 'exp' claim found in token")
                return nil
            }
            
            guard let sub = json["sub"] as? String else {
                print("DEBUG: No 'sub' claim found in token")
                return nil
            }
            
            return JWTPayload(exp: exp, sub: sub)
        } catch {
            print("DEBUG: Error parsing JWT payload: \(error)")
            return nil
        }
    }
}
