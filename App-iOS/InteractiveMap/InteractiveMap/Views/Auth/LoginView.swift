// App-iOS/InteractiveMap/InteractiveMap/Views/Auth/LoginView.swift

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var isRegistering: Bool
    
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            // Background tap gesture to dismiss keyboard
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Text("Welcome Back")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    authViewModel.login(username: username, password: password)
                    if authViewModel.isAuthenticated {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Login")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(username.isEmpty || password.isEmpty || authViewModel.isLoading)
                
                Button(action: {
                    isRegistering = true
                }) {
                    Text("Don't have an account? Register")
                        .foregroundColor(.blue)
                }
                .padding(.top, 10)
                
                if authViewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
