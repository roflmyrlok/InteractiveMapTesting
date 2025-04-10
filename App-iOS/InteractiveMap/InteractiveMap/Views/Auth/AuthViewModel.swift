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
    
    func register(username: String, email: String, password: String, firstName: String, lastName: String) {
        isLoading = true
        errorMessage = nil
        
        authService.register(username: username, email: email, password: password, firstName: firstName, lastName: lastName) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if success {
                    self?.login(username: username, password: password)
                } else {
                    self?.errorMessage = error ?? "Registration failed"
                }
            }
        }
    }
    
    func logout() {
        authService.logout()
        isAuthenticated = false
    }
    
    func skipLogin() {
        isAuthenticated = true
    }
    
    func checkAuthStatus() {
        isAuthenticated = TokenManager.shared.isAuthenticated
    }
}
