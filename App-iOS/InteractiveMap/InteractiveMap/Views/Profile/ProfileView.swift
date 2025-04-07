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
    
    init() {
        // Initialize the view model with the auth view model that will be injected as an environment object
        // This is a workaround since we can't directly initialize with an @EnvironmentObject
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        VStack {
            if authViewModel.isAuthenticated {
                // Authenticated profile content
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                            .padding(.top, 20)
                        
                        if let user = viewModel.user {
                            Text("Welcome, \(user.firstName)!")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ProfileInfoRow(title: "Username", value: user.username)
                                ProfileInfoRow(title: "Email", value: user.email)
                                ProfileInfoRow(title: "Name", value: "\(user.firstName) \(user.lastName)")
                                ProfileInfoRow(title: "Member since", value: formatDate(user.createdAt))
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        } else {
                            Text("Welcome!")
                                .font(.title)
                                .fontWeight(.bold)
                                
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            }
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        Button(action: {
                            viewModel.logout()
                        }) {
                            Text("Logout")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            } else {
                // Unauthenticated profile view
                VStack(spacing: 20) {
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                    
                    Text("Not Logged In")
                        .font(.title)
                        .fontWeight(.medium)
                    
                    Text("Sign in to access your profile and leave reviews")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showLoginSheet = true
                    }) {
                        Text("Login / Register")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showLoginSheet) {
            AuthView()
                .environmentObject(authViewModel)
        }
        .onAppear {
            // This is important to update the view model's reference to the current authViewModel
            viewModel.updateAuthViewModel(authViewModel)
            
            if authViewModel.isAuthenticated {
                viewModel.loadUserProfile()
            }
        }
        .refreshable {
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
    
    private func formatDate(_ dateString: String) -> String {
        // Try to parse the date string
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }

        return dateString
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.vertical, 4)
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
