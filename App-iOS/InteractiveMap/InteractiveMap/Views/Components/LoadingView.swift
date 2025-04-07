//
//  LoadingView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .padding(.top, 10)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.7))
            )
        }
    }
}