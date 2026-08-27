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
struct BuiltInModel: Identifiable, Hashable {
    var id: String { filename }
    let name: String
    let filename: String
    let systemIcon: String
    let subtitle: String
    
    static let samples: [BuiltInModel] = [
        BuiltInModel(
            name: "Model 1",
            filename: "Model1.usdz",
            systemIcon: "cube.fill",
            subtitle: "Sample 3D Asset • USDZ"
        ),
        BuiltInModel(
            name: "Model 2",
            filename: "Model2.usdz",
            systemIcon: "cube.transparent",
            subtitle: "Sample 3D Asset • USDZ"
        ),
        BuiltInModel(
            name: "Model 3",
            filename: "Model3.usdz",
            systemIcon: "sparkles",
            subtitle: "Sample 3D Asset • USDZ"
        )
    ]
}
