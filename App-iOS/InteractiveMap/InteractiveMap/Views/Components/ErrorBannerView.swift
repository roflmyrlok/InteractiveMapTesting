//
//  ErrorBannerView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI

struct ErrorBannerView: View {
    let message: String
    let dismissAction: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                
                Text(message)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.red)
            .cornerRadius(8)
            .padding()
            
            Spacer()
        }
    }
}