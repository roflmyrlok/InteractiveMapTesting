//
//  CacheStatusView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI

struct CacheStatusView: View {
    @StateObject private var cacheStatusViewModel = CacheStatusViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Cache Statistics")) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                        Text("Cached Locations")
                        Spacer()
                        Text("\(cacheStatusViewModel.cacheStatus.locationCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                        Text("Cached Reviews")
                        Spacer()
                        Text("\(cacheStatusViewModel.cacheStatus.reviewCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock.circle.fill")
                            .foregroundColor(.green)
                        Text("Recently Viewed")
                        Spacer()
                        Text("\(cacheStatusViewModel.cacheStatus.lastViewedCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundColor(.purple)
                        Text("Cache Size")
                        Spacer()
                        Text(cacheStatusViewModel.cacheStatus.cacheSize)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Recently Viewed Locations")) {
                    if cacheStatusViewModel.lastViewedLocations.isEmpty {
                        Text("No recently viewed locations")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(cacheStatusViewModel.lastViewedLocations) { location in
                            NavigationLink(destination: LocationDetailView(location: location, isAuthenticated: TokenManager.shared.isAuthenticated)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(getLocationDisplayName(location))
                                        .font(.headline)
                                    Text(location.address)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Cache Management")) {
                    Button(action: {
                        cacheStatusViewModel.refreshCacheStatus()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                            Text("Refresh Cache Status")
                        }
                    }
                    
                    Button(action: {
                        cacheStatusViewModel.clearExpiredCache()
                    }) {
                        HStack {
                            Image(systemName: "trash.circle")
                                .foregroundColor(.orange)
                            Text("Clear Expired Cache")
                        }
                    }
                    
                    Button(action: {
                        cacheStatusViewModel.showClearAllAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear All Cache")
                        }
                    }
                }
                
                Section(footer: Text("Cache helps provide faster access to locations and reviews, and enables offline viewing of previously visited content.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Cache Status")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $cacheStatusViewModel.showClearAllAlert) {
                Alert(
                    title: Text("Clear All Cache"),
                    message: Text("This will remove all cached locations and reviews. You'll need to reload content when viewing locations. Are you sure?"),
                    primaryButton: .destructive(Text("Clear All")) {
                        cacheStatusViewModel.clearAllCache()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                cacheStatusViewModel.loadCacheStatus()
            }
        }
    }
    
    private func getLocationDisplayName(_ location: Location) -> String {
        if let typeDetail = location.details.first(where: { 
            $0.propertyName.lowercased() == "sheltertype" || 
            $0.propertyName.lowercased() == "type" 
        }) {
            return typeDetail.propertyValue
        }
        return location.address
    }
}

class CacheStatusViewModel: ObservableObject {
    @Published var cacheStatus = CacheStatus(locationCount: 0, reviewCount: 0, lastViewedCount: 0, cacheSize: "0 KB")
    @Published var lastViewedLocations: [Location] = []
    @Published var showClearAllAlert = false
    
    private let cacheManager = CacheManager.shared
    
    func loadCacheStatus() {
        refreshCacheStatus()
        loadLastViewedLocations()
    }
    
    func refreshCacheStatus() {
        cacheStatus = cacheManager.getCacheStatus()
    }
    
    func loadLastViewedLocations() {
        lastViewedLocations = cacheManager.getLastViewedLocationObjects()
    }
    
    func clearExpiredCache() {
        cacheManager.clearExpiredCache()
        refreshCacheStatus()
        loadLastViewedLocations()
    }
    
    func clearAllCache() {
        cacheManager.clearAllCache()
        refreshCacheStatus()
        loadLastViewedLocations()
    }
}
