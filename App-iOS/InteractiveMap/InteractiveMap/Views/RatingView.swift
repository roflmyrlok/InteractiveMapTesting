//
//  RatingView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI

struct RatingView: View {
    let rating: Int
    let maxRating: Int
    let size: CGFloat
    
    init(rating: Int, maxRating: Int = 5, size: CGFloat = 20) {
        self.rating = rating
        self.maxRating = maxRating
        self.size = size
    }
    
    var body: some View {
        HStack {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .font(.system(size: size))
            }
        }
    }
}