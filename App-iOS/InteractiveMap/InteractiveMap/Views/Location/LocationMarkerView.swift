//
//  LocationMarkerView.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


import SwiftUI

struct LocationMarkerView: View {
    let location: Location
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 34, height: 34)
                
                Image(systemName: "mappin")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(location.name)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .shadow(radius: 1)
                .padding(.top, 4)
        }
    }
}