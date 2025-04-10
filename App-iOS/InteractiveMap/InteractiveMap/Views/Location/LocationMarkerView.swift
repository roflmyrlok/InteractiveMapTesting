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
            
            Circle()
                .fill(Color.green)
                .frame(width: 34, height: 34)
            
            Image(systemName: "mappin")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
