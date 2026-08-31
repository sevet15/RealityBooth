//
//  ARSurfaceManager.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 31/08/26.
//

import RealityKit
import ARKit

/// Dedicated manager for surface raycasting, LiDAR mesh hit-testing, and model grounding
struct ARSurfaceManager {
    /// Performs a prioritized surface raycast against LiDAR meshes, detected planes, and estimated surfaces
    static func performSurfaceRaycast(at point: CGPoint, in arView: ARView) -> simd_float4x4? {
        // 1. Priority 1: Exact physical surface geometry (LiDAR Scene Reconstruction Mesh & ARKit Planes)
        if let result = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .any).first {
            return result.worldTransform
        }
        
        // 2. Priority 2: Infinite plane extension of confirmed detected physical surfaces
        if let result = arView.raycast(from: point, allowing: .existingPlaneInfinite, alignment: .any).first {
            return result.worldTransform
        }
        
        // 3. Priority 3: Estimated surface (Horizontal & Vertical rapid placement)
        if let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first {
            return result.worldTransform
        }
        
        // 4. Priority 4: Native ARKit Hit-Test across detected planes & estimated surfaces
        let planeHits = arView.hitTest(
            point,
            types: [.existingPlaneUsingGeometry, .existingPlaneUsingExtent, .estimatedHorizontalPlane, .estimatedVerticalPlane, .featurePoint]
        )
        if let hit = planeHits.first {
            return hit.worldTransform
        }
        
        return nil
    }
}
