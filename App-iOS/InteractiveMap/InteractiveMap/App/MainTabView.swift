//
//  MainTabView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            NavigationView {
                ExploreMapView()
            }
            .tabItem {
                Label("Explore", systemImage: "map")
            }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}