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
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .shadow(color: Color.black.opacity(0.3), radius: 3)
            
            Circle()
                .fill(Color.red)
                .frame(width: 34, height: 34)
            
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
