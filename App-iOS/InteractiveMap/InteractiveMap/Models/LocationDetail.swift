//
//  LocationDetail.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//

import Foundation

struct LocationDetail: Codable, Identifiable {
    let id: String
    let propertyName: String
    let propertyValue: String
    
    private enum CodingKeys: String, CodingKey {
        case id, propertyName, propertyValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        propertyName = try container.decode(String.self, forKey: .propertyName)
        propertyValue = try container.decode(String.self, forKey: .propertyValue)
    }
}
