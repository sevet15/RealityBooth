//
//  ARModelItem.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import Foundation
import SwiftUI

/// Represents a 3D model instance managed within the AR session
struct ARModelItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var fileURL: URL
    var isBuiltIn: Bool
    var isPlaced: Bool
    var systemIcon: String
    
    init(
        id: UUID = UUID(),
        name: String,
        fileURL: URL,
        isBuiltIn: Bool = false,
        isPlaced: Bool = false,
        systemIcon: String = "cube.fill"
    ) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.isBuiltIn = isBuiltIn
        self.isPlaced = isPlaced
        self.systemIcon = systemIcon
    }
    
    static func == (lhs: ARModelItem, rhs: ARModelItem) -> Bool {
        lhs.id == rhs.id && lhs.isPlaced == rhs.isPlaced && lhs.name == rhs.name
    }
}

/// Sample models bundled within the application for quick testing
struct BuiltInModel {
    let name: String
    let filename: String
    let systemIcon: String
    let subtitle: String
    
    static let samples: [BuiltInModel] = [
        BuiltInModel(name: "Ferrari", filename: "Ferrari.usdz", systemIcon: "car.fill", subtitle: "Sports Car 3D Model"),
        BuiltInModel(name: "Enchant", filename: "Enchant.usdz", systemIcon: "sparkles", subtitle: "Character 3D Model")
    ]
}
