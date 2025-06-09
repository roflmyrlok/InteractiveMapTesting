//
//  InteractiveRatingView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import SwiftUI

struct InteractiveRatingView: View {
    @Binding var rating: Int
    let maxRating: Int
    let size: CGFloat
    let spacing: CGFloat
    let fillColor: Color
    let strokeColor: Color
    
    init(
        rating: Binding<Int>,
        maxRating: Int = 5,
        size: CGFloat = 30,
        spacing: CGFloat = 8,
        fillColor: Color = .yellow,
        strokeColor: Color = .gray
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.size = size
        self.spacing = spacing
        self.fillColor = fillColor
        self.strokeColor = strokeColor
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        rating = index
                    }
                }) {
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? fillColor : strokeColor)
                        .font(.system(size: size))
                        .scaleEffect(index <= rating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: rating)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct ReadOnlyRatingView: View {
    let rating: Int
    let maxRating: Int
    let size: CGFloat
    let spacing: CGFloat
    let fillColor: Color
    let strokeColor: Color
    
    init(
        rating: Int,
        maxRating: Int = 5,
        size: CGFloat = 20,
        spacing: CGFloat = 2,
        fillColor: Color = .yellow,
        strokeColor: Color = .gray
    ) {
        self.rating = rating
        self.maxRating = maxRating
        self.size = size
        self.spacing = spacing
        self.fillColor = fillColor
        self.strokeColor = strokeColor
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? fillColor : strokeColor)
                    .font(.system(size: size))
            }
        }
    }
}

// Legacy RatingView for backward compatibility
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
        ReadOnlyRatingView(
            rating: rating,
            maxRating: maxRating,
            size: size
        )
    }
}
