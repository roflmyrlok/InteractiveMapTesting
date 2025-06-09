//
//  OfflineSearchView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI

struct OfflineSearchView: View {
    @StateObject private var searchManager = SearchManager()
    @State private var searchText = ""
    @State private var searchResults: [LocationSearchResult] = []
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search cached locations...", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            performOfflineSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Offline indicator
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.red)
                    Text("Searching cached locations only")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search Results
                if searchText.isEmpty {
                    // Show all cached locations
                    VStack {
                        HStack {
                            Text("All Cached Locations (\(CacheManager.shared.getCachedLocations().count))")
                                .font(.headline)
                                .padding(.horizontal)
                            Spacer()
                        }
                        .padding(.top)
                        
                        List {
                            ForEach(CacheManager.shared.getCachedLocations(), id: \.id) { location in
                                NavigationLink(destination: LocationDetailView(location: location, isAuthenticated: TokenManager.shared.isAuthenticated)) {
                                    OfflineLocationRow(location: location)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No cached locations found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Try a different search term or connect to internet for live search")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchResults) { result in
                            NavigationLink(destination: LocationDetailView(location: result.location, isAuthenticated: TokenManager.shared.isAuthenticated)) {
                                OfflineLocationRow(location: result.location)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Offline Search")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func performOfflineSearch(query: String) {
        if query.isEmpty {
            searchResults = []
            return
        }
        
        searchResults = searchManager.searchOfflineOnly(query: query)
    }
}

struct OfflineLocationRow: View {
    let location: Location
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive")
                .foregroundColor(.red)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(getLocationDisplayName(location))
                    .font(.headline)
                
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let district = getLocationDistrict(location) {
                    Text(district)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("Cached")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
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
    
    private func getLocationDistrict(_ location: Location) -> String? {
        return location.details.first(where: { $0.propertyName.lowercased() == "district" })?.propertyValue
    }
}
