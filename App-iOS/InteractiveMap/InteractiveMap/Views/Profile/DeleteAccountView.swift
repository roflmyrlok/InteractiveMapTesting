//
//  DeleteAccountView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 09.06.2025.
//

import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = DeleteAccountViewModel()
    @State private var currentPassword = ""
    @State private var showingFinalConfirmation = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onAccountDeleted: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            Text("Delete Account")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        
                        Text("This action is permanent and cannot be undone.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What will happen:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "person.slash")
                                    .foregroundColor(.red)
                                    .frame(width: 20)
                                Text("Your account will be permanently deleted")
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                Image(systemName: "star.slash")
                                    .foregroundColor(.red)
                                    .frame(width: 20)
                                Text("All your reviews will be removed")
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 20)
                                Text("This action cannot be reversed")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter your password to confirm:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        SecureField("Current password", text: $currentPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showingFinalConfirmation = true
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Deleting Account...")
                                } else {
                                    Image(systemName: "trash.fill")
                                    Text("Delete My Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(currentPassword.isEmpty ? Color.gray : Color.red)
                            .cornerRadius(8)
                        }
                        .disabled(currentPassword.isEmpty || viewModel.isLoading)
                        
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Delete Account")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert("Final Confirmation", isPresented: $showingFinalConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you absolutely sure? This will permanently delete your account and all associated data.")
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

// MARK: - Private Methods
extension DeleteAccountView {
    private func deleteAccount() {
        let request = DeleteAccountRequest(currentPassword: currentPassword)
        
        viewModel.deleteAccount(request: request) { (success: Bool, message: String?) in
            DispatchQueue.main.async {
                if success {
                    onAccountDeleted()
                    presentationMode.wrappedValue.dismiss()
                } else {
                    alertMessage = message ?? "Failed to delete account. Please try again."
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - DeleteAccountViewModel
class DeleteAccountViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userService = UserService()
    
    func deleteAccount(request: DeleteAccountRequest, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        userService.deleteAccount(request: request) { [weak self] (success: Bool, message: String?) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if !success {
                    self?.errorMessage = message
                }
                completion(success, message)
            }
        }
    }
}
