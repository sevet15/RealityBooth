//
//  ARSelectionIndicator.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 31/08/26.
//

import UIKit
import RealityKit

/// Dedicated manager responsible for generating and anchoring 3D selection outline halo rings
enum ARSelectionIndicator {
    static let indicatorName = "SelectionRingIndicator"
    
    /// Generates a vector circular outline ring mesh with double-sided polygon winding
    static func generateRingMesh(radius: Float, thickness: Float = 0.016, segments: Int = 64) -> MeshResource? {
        var desc = MeshDescriptor(name: "SelectionOutlineRing")
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        let innerR = radius
        let outerR = radius + thickness
        
        for i in 0...segments {
            let angle = Float(i) * (2.0 * .pi / Float(segments))
            let cosA = cos(angle)
            let sinA = sin(angle)
            
            positions.append(SIMD3<Float>(innerR * cosA, 0, innerR * sinA))
            positions.append(SIMD3<Float>(outerR * cosA, 0, outerR * sinA))
        }
        
        for i in 0..<segments {
            let v0 = UInt32(i * 2)
            let v1 = UInt32(i * 2 + 1)
            let v2 = UInt32((i + 1) * 2)
            let v3 = UInt32((i + 1) * 2 + 1)
            
            // Double-sided quad rendering for 100% visibility from all viewing angles
            indices.append(contentsOf: [v0, v1, v2, v1, v3, v2])
            indices.append(contentsOf: [v0, v2, v1, v1, v2, v3])
        }
        
        desc.positions = MeshBuffers.Positions(positions)
        desc.primitives = .triangles(indices)
        
        return try? MeshResource.generate(from: [desc])
    }
    
    /// Creates a ModelEntity configured as a crisp blue circular outline halo
    static func createIndicatorEntity(for entity: Entity) -> ModelEntity? {
        let bounds = entity.visualBounds(relativeTo: entity)
        let radius = max(0.30, max(bounds.extents.x, bounds.extents.z) * 0.60)
        
        guard let ringMesh = generateRingMesh(radius: radius, thickness: 0.016, segments: 64) else { return nil }
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor(red: 0.0, green: 0.52, blue: 1.0, alpha: 1.0))
        
        let ringEntity = ModelEntity(mesh: ringMesh, materials: [material])
        ringEntity.name = indicatorName
        ringEntity.position = SIMD3<Float>(bounds.center.x, bounds.min.y + 0.005, bounds.center.z)
        return ringEntity
    }
}
