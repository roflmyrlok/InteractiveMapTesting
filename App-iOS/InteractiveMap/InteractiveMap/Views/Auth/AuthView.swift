//
//  AuthView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isRegistering = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isRegistering {
                    RegisterView(isRegistering: $isRegistering)
                        .environmentObject(authViewModel)
                } else {
                    LoginView(isRegistering: $isRegistering)
                        .environmentObject(authViewModel)
                }
            }
            .navigationTitle(isRegistering ? "Create Account" : "Login")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

