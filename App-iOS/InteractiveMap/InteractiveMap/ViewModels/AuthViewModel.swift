//
//  AuthViewModel.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import Foundation

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = TokenManager.shared.isAuthenticated
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService()
    
    func login(username: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        authService.login(username: username, password: password) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if success {
                    self?.isAuthenticated = true
                } else {
                    self?.errorMessage = error ?? "Login failed"
                }
            }
        }
    }
    
    func logout() {
        authService.logout()
        isAuthenticated = false
    }
}