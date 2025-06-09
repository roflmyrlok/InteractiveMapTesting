//
//  CacheManager.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

class CacheManager {
    static let shared = CacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    private let maxCachedLocations = 20
    private let maxCachedReviews = 100
    private let cacheExpirationDays = 7
    
    private enum CacheKeys {
        static let cachedLocations = "cached_locations"
        static let cachedReviews = "cached_reviews"
        static let lastViewedLocations = "last_viewed_locations"
        static let locationTimestamps = "location_timestamps"
        static let reviewTimestamps = "review_timestamps"
    }
    
    private init() {
        createCacheDirectoryIfNeeded()
        cleanExpiredCache()
    }
    
    private func createCacheDirectoryIfNeeded() {
        guard let cacheURL = getCacheDirectoryURL() else { return }
        
        if !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func getCacheDirectoryURL() -> URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("InteractiveMapCache")
    }
    
    // MARK: - Location Caching
    
    func cacheLocation(_ location: Location) {
        var cachedLocations = getCachedLocations()
        var locationTimestamps = getLocationTimestamps()
        
        // Remove existing entry if present
        cachedLocations.removeAll { $0.id == location.id }
        
        // Add new entry at the beginning
        cachedLocations.insert(location, at: 0)
        
        // Limit cache size
        if cachedLocations.count > maxCachedLocations {
            let removedLocation = cachedLocations.removeLast()
            locationTimestamps.removeValue(forKey: removedLocation.id)
        }
        
        // Update timestamp
        locationTimestamps[location.id] = Date()
        
        // Save to cache
        saveCachedLocations(cachedLocations)
        saveLocationTimestamps(locationTimestamps)
    }
    
    func cacheLocationAsViewed(_ location: Location) {
        // Cache the location data
        cacheLocation(location)
        
        // Update last viewed (only when actually opened/viewed)
        updateLastViewedLocation(location.id)
    }
    
    func getCachedLocation(id: String) -> Location? {
        let cachedLocations = getCachedLocations()
        return cachedLocations.first { $0.id == id }
    }
    
    func getCachedLocations() -> [Location] {
        guard let data = userDefaults.data(forKey: CacheKeys.cachedLocations) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            return try decoder.decode([Location].self, from: data)
        } catch {
            print("Error decoding cached locations: \(error)")
            return []
        }
    }
    
    private func saveCachedLocations(_ locations: [Location]) {
        do {
            let encoder = JSONEncoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            
            let data = try encoder.encode(locations)
            userDefaults.set(data, forKey: CacheKeys.cachedLocations)
        } catch {
            print("Error encoding cached locations: \(error)")
        }
    }
    
    // MARK: - Review Caching
    
    func cacheReviews(_ reviews: [Review], for locationId: String) {
        var cachedReviews = getCachedReviews()
        var reviewTimestamps = getReviewTimestamps()
        
        // Remove existing reviews for this location
        cachedReviews.removeAll { $0.locationId == locationId }
        
        // Add new reviews
        cachedReviews.append(contentsOf: reviews)
        
        // Sort by creation date (newest first)
        cachedReviews.sort { $0.createdAt > $1.createdAt }
        
        // Limit cache size
        if cachedReviews.count > maxCachedReviews {
            cachedReviews = Array(cachedReviews.prefix(maxCachedReviews))
        }
        
        // Update timestamps for these reviews
        let currentTime = Date()
        for review in reviews {
            reviewTimestamps[review.id] = currentTime
        }
        
        // Save to cache
        saveCachedReviews(cachedReviews)
        saveReviewTimestamps(reviewTimestamps)
    }
    
    func getCachedReviews(for locationId: String) -> [Review] {
        let allReviews = getCachedReviews()
        return allReviews.filter { $0.locationId == locationId }
    }
    
    func getCachedReviews() -> [Review] {
        guard let data = userDefaults.data(forKey: CacheKeys.cachedReviews) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            return try decoder.decode([Review].self, from: data)
        } catch {
            print("Error decoding cached reviews: \(error)")
            return []
        }
    }
    
    private func saveCachedReviews(_ reviews: [Review]) {
        do {
            let encoder = JSONEncoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            
            let data = try encoder.encode(reviews)
            userDefaults.set(data, forKey: CacheKeys.cachedReviews)
        } catch {
            print("Error encoding cached reviews: \(error)")
        }
    }
    
    // MARK: - Last Viewed Locations
    
    private func updateLastViewedLocation(_ locationId: String) {
        var lastViewed = getLastViewedLocations()
        
        // Remove if already exists
        lastViewed.removeAll { $0 == locationId }
        
        // Add to front
        lastViewed.insert(locationId, at: 0)
        
        // Keep only last 10
        if lastViewed.count > 10 {
            lastViewed = Array(lastViewed.prefix(10))
        }
        
        userDefaults.set(lastViewed, forKey: CacheKeys.lastViewedLocations)
    }
    
    func getLastViewedLocations() -> [String] {
        return userDefaults.stringArray(forKey: CacheKeys.lastViewedLocations) ?? []
    }
    
    func getLastViewedLocationObjects() -> [Location] {
        let locationIds = getLastViewedLocations()
        let cachedLocations = getCachedLocations()
        
        return locationIds.compactMap { id in
            cachedLocations.first { $0.id == id }
        }
    }
    
    // MARK: - Timestamps Management
    
    private func getLocationTimestamps() -> [String: Date] {
        guard let data = userDefaults.data(forKey: CacheKeys.locationTimestamps) else {
            return [:]
        }
        
        do {
            return try JSONDecoder().decode([String: Date].self, from: data)
        } catch {
            print("Error decoding location timestamps: \(error)")
            return [:]
        }
    }
    
    private func saveLocationTimestamps(_ timestamps: [String: Date]) {
        do {
            let data = try JSONEncoder().encode(timestamps)
            userDefaults.set(data, forKey: CacheKeys.locationTimestamps)
        } catch {
            print("Error encoding location timestamps: \(error)")
        }
    }
    
    private func getReviewTimestamps() -> [String: Date] {
        guard let data = userDefaults.data(forKey: CacheKeys.reviewTimestamps) else {
            return [:]
        }
        
        do {
            return try JSONDecoder().decode([String: Date].self, from: data)
        } catch {
            print("Error decoding review timestamps: \(error)")
            return [:]
        }
    }
    
    private func saveReviewTimestamps(_ timestamps: [String: Date]) {
        do {
            let data = try JSONEncoder().encode(timestamps)
            userDefaults.set(data, forKey: CacheKeys.reviewTimestamps)
        } catch {
            print("Error encoding review timestamps: \(error)")
        }
    }
    
    // MARK: - Cache Expiration
    
    private func cleanExpiredCache() {
        let expirationDate = Calendar.current.date(byAdding: .day, value: -cacheExpirationDays, to: Date()) ?? Date()
        
        // Clean expired locations
        let locationTimestamps = getLocationTimestamps()
        var cachedLocations = getCachedLocations()
        var updatedLocationTimestamps = locationTimestamps
        
        cachedLocations.removeAll { location in
            if let timestamp = locationTimestamps[location.id], timestamp < expirationDate {
                updatedLocationTimestamps.removeValue(forKey: location.id)
                return true
            }
            return false
        }
        
        saveCachedLocations(cachedLocations)
        saveLocationTimestamps(updatedLocationTimestamps)
        
        // Clean expired reviews
        let reviewTimestamps = getReviewTimestamps()
        var cachedReviews = getCachedReviews()
        var updatedReviewTimestamps = reviewTimestamps
        
        cachedReviews.removeAll { review in
            if let timestamp = reviewTimestamps[review.id], timestamp < expirationDate {
                updatedReviewTimestamps.removeValue(forKey: review.id)
                return true
            }
            return false
        }
        
        saveCachedReviews(cachedReviews)
        saveReviewTimestamps(updatedReviewTimestamps)
    }
    
    // MARK: - Cache Status
    
    func isLocationCached(_ locationId: String) -> Bool {
        let cachedLocations = getCachedLocations()
        return cachedLocations.contains { $0.id == locationId }
    }
    
    func areReviewsCached(for locationId: String) -> Bool {
        let cachedReviews = getCachedReviews(for: locationId)
        return !cachedReviews.isEmpty
    }
    
    func getCacheStatus() -> CacheStatus {
        let locations = getCachedLocations()
        let reviews = getCachedReviews()
        let lastViewed = getLastViewedLocationObjects()
        
        return CacheStatus(
            locationCount: locations.count,
            reviewCount: reviews.count,
            lastViewedCount: lastViewed.count,
            cacheSize: calculateCacheSize()
        )
    }
    
    private func calculateCacheSize() -> String {
        let locationsData = userDefaults.data(forKey: CacheKeys.cachedLocations)?.count ?? 0
        let reviewsData = userDefaults.data(forKey: CacheKeys.cachedReviews)?.count ?? 0
        let totalBytes = locationsData + reviewsData
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalBytes))
    }
    
    // MARK: - Clear Cache
    
    func clearAllCache() {
        userDefaults.removeObject(forKey: CacheKeys.cachedLocations)
        userDefaults.removeObject(forKey: CacheKeys.cachedReviews)
        userDefaults.removeObject(forKey: CacheKeys.lastViewedLocations)
        userDefaults.removeObject(forKey: CacheKeys.locationTimestamps)
        userDefaults.removeObject(forKey: CacheKeys.reviewTimestamps)
    }
    
    func clearExpiredCache() {
        cleanExpiredCache()
    }
}

struct CacheStatus {
    let locationCount: Int
    let reviewCount: Int
    let lastViewedCount: Int
    let cacheSize: String
}
