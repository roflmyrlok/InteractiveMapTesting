//
//  AsyncImageView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI

struct AsyncImageView: View {
    let url: String
    let width: CGFloat
    let height: CGFloat
    
    @StateObject private var imageLoader = AsyncImageLoader()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: height)
            
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if imageLoader.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
        .onAppear {
            imageLoader.loadImage(from: url)
        }
    }
}

class AsyncImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    func loadImage(from url: String) {
        guard !url.isEmpty else { return }
        
        isLoading = true
        
        NetworkManager.shared.downloadImage(from: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let data):
                    self?.image = UIImage(data: data)
                case .failure(let error):
                    print("Failed to load image: \(error)")
                    self?.image = nil
                }
            }
        }
    }
}
