//
//  ProfileViewModel.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var alertItem: AlertItem?
    @Published var lastRefreshDate: Date?
    
    private let userService = UserService()
    private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func updateAuthViewModel(_ viewModel: AuthViewModel) {
        self.authViewModel = viewModel
    }
    
    func loadUserProfile(forceRefresh: Bool = false) {
        guard authViewModel.isAuthenticated else {
            user = nil
            return
        }
        
        // Avoid unnecessary requests if we recently loaded the profile
        if !forceRefresh, let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < 30 { // 30 seconds cache
            return
        }
        
        isLoading = true
        
        userService.getCurrentUser { [weak self] (user: User?, error: Error?) in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.lastRefreshDate = Date()
                
                if let error = error {
                    // Check if it's an authentication error
                    let nsError = error as NSError
                    if nsError.code == 401 || nsError.domain == "UserService" {
                        // Invalid token - logout user
                        self?.logout()
                        self?.alertItem = AlertItem(
                            title: "Session Expired",
                            message: "Your session has expired. Please log in again."
                        )
                    } else {
                        // Other errors - show alert but keep user logged in
                        self?.alertItem = AlertItem(
                            title: "Error Loading Profile",
                            message: error.localizedDescription
                        )
                    }
                } else if let user = user {
                    self?.user = user
                }
            }
        }
    }
    
    func refreshProfile() {
        loadUserProfile(forceRefresh: true)
    }
    
    func logout() {
        authViewModel.logout()
        self.user = nil
        self.lastRefreshDate = nil
    }
    
    // Helper methods for UI
    func getUserInitials() -> String {
        guard let user = user else { return "?" }
        return user.initials
    }
    
    func getFullName() -> String {
        guard let user = user else { return "Unknown User" }
        return user.fullName
    }
    
    func getMemberSince() -> String {
        guard let user = user else { return "Unknown" }
        return formatDate(user.createdAt, style: .long)
    }
    
    func getLastLogin() -> String? {
        guard let user = user, let lastLogin = user.lastLoginDate else { return nil }
        return formatRelativeDate(lastLogin)
    }
    
    private func formatDate(_ dateString: String, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: dateString) else {
            return "Unknown"
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = style
        return displayFormatter.string(from: date)
    }
    
    private func formatRelativeDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        guard let date = formatter.date(from: dateString) else {
            return "Unknown"
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(timeInterval / 86400)
            if days < 7 {
                return "\(days) day\(days == 1 ? "" : "s") ago"
            } else {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                return displayFormatter.string(from: date)
            }
        }
    }
}
