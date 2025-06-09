//
//  ReviewCardView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI

struct ReviewCardView: View {
    let review: Review
    @StateObject private var imageLoader = ReviewImageLoader()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RatingView(rating: review.rating)
                Spacer()
                Text(formatDate(review.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(review.content)
                .padding(.top, 4)
            
            // Display images if available
            if !review.imageUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(review.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                            ReviewImageView(imageUrl: imageUrl, imageLoader: imageLoader)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 120)
                .padding(.top, 8)
            }
            
            Divider()
        }
        .padding(.vertical, 8)
        .onAppear {
            if !review.imageUrls.isEmpty {
                imageLoader.loadImages(urls: review.imageUrls)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ReviewImageView: View {
    let imageUrl: String
    @ObservedObject var imageLoader: ReviewImageLoader
    @State private var showingFullscreen = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
            
            if let image = imageLoader.images[imageUrl] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        showingFullscreen = true
                    }
            } else if imageLoader.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .sheet(isPresented: $showingFullscreen) {
            if let image = imageLoader.images[imageUrl] {
                FullscreenImageView(image: image)
            }
        }
    }
}

struct FullscreenImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

class ReviewImageLoader: ObservableObject {
    @Published var images: [String: UIImage] = [:]
    @Published var isLoading = false
    
    private var loadingUrls: Set<String> = []
    
    func loadImages(urls: [String]) {
        for url in urls {
            loadImage(url: url)
        }
    }
    
    private func loadImage(url: String) {
        // Check if already loaded or loading
        if images[url] != nil || loadingUrls.contains(url) {
            return
        }
        
        loadingUrls.insert(url)
        isLoading = true
        
        NetworkManager.shared.downloadImage(from: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingUrls.remove(url)
                self?.isLoading = self?.loadingUrls.isEmpty == false
                
                switch result {
                case .success(let data):
                    if let image = UIImage(data: data) {
                        self?.images[url] = image
                    }
                case .failure(let error):
                    print("Failed to load image from \(url): \(error)")
                }
            }
        }
    }
}
