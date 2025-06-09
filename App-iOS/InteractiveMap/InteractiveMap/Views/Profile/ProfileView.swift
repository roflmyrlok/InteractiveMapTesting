//
//  ProfileView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var showLoginSheet = false
    @State private var showCacheStatus = false
    @State private var showChangePassword = false
    @State private var showDeleteAccount = false
    
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        VStack {
            if authViewModel.isAuthenticated {
                // Authenticated profile content
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        // Profile Header
                        VStack(spacing: 16) {
                            // Profile Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 120)
                                
                                if let user = viewModel.user {
                                    Text(getUserInitials(user))
                                        .font(.system(size: 36, weight: .semibold))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                            }
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            // User Name and Welcome
                            VStack(spacing: 8) {
                                if let user = viewModel.user {
                                    Text("\(user.firstName) \(user.lastName)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("@\(user.username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                } else if viewModel.isLoading {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("Loading profile...")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                } else {
                                    Text("Welcome!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Account Information Section
                        if let user = viewModel.user {
                            VStack(spacing: 16) {
                                SectionHeaderView(title: "Account Information", icon: "person.text.rectangle")
                                
                                VStack(spacing: 12) {
                                    AccountInfoRow(
                                        icon: "envelope.fill",
                                        title: "Email",
                                        value: user.email,
                                        iconColor: .blue
                                    )
                                    
                                    AccountInfoRow(
                                        icon: "person.fill",
                                        title: "Username",
                                        value: user.username,
                                        iconColor: .green
                                    )
                                    
                                    AccountInfoRow(
                                        icon: "calendar",
                                        title: "Member Since",
                                        value: formatMemberSinceDate(user.createdAt),
                                        iconColor: .orange
                                    )
                                    
                                    if let lastLogin = user.lastLoginDate {
                                        AccountInfoRow(
                                            icon: "clock.fill",
                                            title: "Last Login",
                                            value: formatLastLoginDate(lastLogin),
                                            iconColor: .purple
                                        )
                                    }
                                    
                                    AccountInfoRow(
                                        icon: "shield.fill",
                                        title: "Role",
                                        value: getRoleDisplayName(user.role),
                                        iconColor: .red
                                    )
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // Account Management Section
                        VStack(spacing: 16) {
                            SectionHeaderView(title: "Account Management", icon: "gearshape.fill")
                            
                            VStack(spacing: 12) {
                                ManagementButton(
                                    icon: "key.fill",
                                    title: "Change Password",
                                    subtitle: "Update your account password",
                                    iconColor: .blue,
                                    action: { showChangePassword = true }
                                )
                                
                                ManagementButton(
                                    icon: "trash.fill",
                                    title: "Delete Account",
                                    subtitle: "Permanently delete your account",
                                    iconColor: .red,
                                    isDestructive: true,
                                    action: { showDeleteAccount = true }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // App Settings Section
                        VStack(spacing: 16) {
                            SectionHeaderView(title: "App Settings", icon: "gear")
                            
                            VStack(spacing: 12) {
                                ManagementButton(
                                    icon: "internaldrive",
                                    title: "Cache Status",
                                    subtitle: "View offline content and storage",
                                    iconColor: .purple,
                                    action: { showCacheStatus = true }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // Logout Button
                        Button(action: {
                            viewModel.logout()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.title3)
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            } else {
                // Unauthenticated profile view
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray.opacity(0.6))
                        
                        VStack(spacing: 12) {
                            Text("Welcome to InteractiveMap")
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("Sign in to access your profile, leave reviews, and personalize your experience")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    Button(action: {
                        showLoginSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                            Text("Sign In / Register")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Divider()
                        .padding(.horizontal, 40)
                    
                    // Cache Status for unauthenticated users
                    Button(action: {
                        showCacheStatus = true
                    }) {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("View Cached Content")
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("Access offline locations and reviews")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("Profile")
        .refreshable {
            if authViewModel.isAuthenticated {
                viewModel.loadUserProfile()
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            AuthView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showCacheStatus) {
            CacheStatusView()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView {
                authViewModel.logout()
            }
        }
        .onAppear {
            viewModel.updateAuthViewModel(authViewModel)
            if authViewModel.isAuthenticated {
                viewModel.loadUserProfile()
            }
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Helper Views
struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}

struct AccountInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ManagementButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDestructive ? .red : .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(isDestructive ? Color.red.opacity(0.05) : Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Helper Functions
extension ProfileView {
    private func getUserInitials(_ user: User) -> String {
        let firstInitial = user.firstName.prefix(1).uppercased()
        let lastInitial = user.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func formatMemberSinceDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            return displayFormatter.string(from: date)
        }
        
        return "Unknown"
    }
    
    private func formatLastLoginDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
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
        
        return "Unknown"
    }
    
    private func getRoleDisplayName(_ role: Int) -> String {
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

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AuthViewModel())
        }
    }
}
