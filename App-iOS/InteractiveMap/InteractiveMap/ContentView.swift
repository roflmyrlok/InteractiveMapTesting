//
//  ContentView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if authViewModel.isAuthenticated {
            MapView(isAuthenticated: $authViewModel.isAuthenticated)
        } else {
            NavigationView {
                LoginView()
            }
        }
    }
}


#Preview {
    ContentView()
}
