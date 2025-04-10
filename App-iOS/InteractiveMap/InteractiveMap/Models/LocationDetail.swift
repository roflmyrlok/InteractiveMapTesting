//
//  LocationDetail.swift
//  InteractiveMap
//
//  Created by Andrii Trybushnyi on 07.04.2025.
//


struct LocationDetail: Codable, Identifiable {
    let id: String
    let propertyName: String
    let propertyValue: String
}