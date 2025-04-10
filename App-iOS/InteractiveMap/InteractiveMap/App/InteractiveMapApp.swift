//
//  InteractiveMapApp.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI

@main
struct InteractiveMapApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authViewModel)
        }
    }
}
