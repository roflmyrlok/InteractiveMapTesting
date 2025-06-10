//
//  ChangePasswordView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 09.06.2025.
//

import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ChangePasswordViewModel()
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var passwordChangeSuccessful = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Password")) {
                    SecureField("Enter current password", text: $currentPassword)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("New Password")) {
                    SecureField("Enter new password", text: $newPassword)
                        .autocapitalization(.none)
                    
                    SecureField("Confirm new password", text: $confirmPassword)
                        .autocapitalization(.none)
                }
                
                Section(footer: Text("Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character.")) {
                    EmptyView()
                }
                
                Section {
                    Button(action: changePassword) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Changing Password...")
                            } else {
                                Text("Change Password")
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(8)
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                    .listRowInsets(EdgeInsets())
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if passwordChangeSuccessful {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8 &&
        isPasswordStrong(newPassword)
    }
    
    private func isPasswordStrong(_ password: String) -> Bool {
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil
        
        return hasUppercase && hasLowercase && hasNumber && hasSpecialChar
    }
    
    private func changePassword() {
        let request = ChangePasswordRequest(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmNewPassword: confirmPassword
        )
        
        viewModel.changePassword(request: request) { (success: Bool, message: String?) in
            DispatchQueue.main.async {
                if success {
                    alertTitle = "Success"
                    alertMessage = "Your password has been changed successfully."
                    passwordChangeSuccessful = true
                } else {
                    alertTitle = "Error"
                    alertMessage = message ?? "Failed to change password. Please try again."
                    passwordChangeSuccessful = false
                }
                showingAlert = true
            }
        }
    }
}

class ChangePasswordViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userService = UserService()
    
    func changePassword(request: ChangePasswordRequest, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        userService.changePassword(request: request) { [weak self] (success: Bool, message: String?) in
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
