//
//  RegisterView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI
struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var isRegistering: Bool
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var showingPasswordError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create an Account")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            VStack(spacing: 15) {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                TextField("First Name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            if showingPasswordError {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Button(action: {
                if password == confirmPassword {
                    authViewModel.register(username: username, email: email, password: password, firstName: firstName, lastName: lastName)
                    if authViewModel.isAuthenticated {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    showingPasswordError = true
                }
            }) {
                Text("Register")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(username.isEmpty || email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty || authViewModel.isLoading)
            
            Button(action: {
                isRegistering = false
            }) {
                Text("Already have an account? Login")
                    .foregroundColor(.blue)
            }
            .padding(.top, 10)
            
            if authViewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .padding()
    }
}
