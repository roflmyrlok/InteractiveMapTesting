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
    
    private let userService = UserService()
    private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func updateAuthViewModel(_ viewModel: AuthViewModel) {
        self.authViewModel = viewModel
    }
    
    func loadUserProfile() {
        guard authViewModel.isAuthenticated else { return }
        
        isLoading = true
        
        userService.getCurrentUser { [weak self] (user: User?, error: Error?) in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.alertItem = AlertItem(
                        title: "Error Loading Profile",
                        message: error.localizedDescription
                    )
                } else if let user = user {
                    self?.user = user
                }
            }
        }
    }
    
    func logout() {
        authViewModel.logout()
        self.user = nil
    }
}
