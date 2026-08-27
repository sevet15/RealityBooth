//
//  ARConstants.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import Foundation
import simd

/// Global constants for AR and 3D object manipulation
enum ARConstants {
    // MARK: - Scale & Transform
    static let defaultScale: SIMD3<Float> = SIMD3<Float>(0.1, 0.1, 0.1)
    static let minScale: Float = 0.001
    static let maxScale: Float = 2.0
    static let defaultOrientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    
    // MARK: - Lighting
    static let directionalLightIntensity: Float = 1500.0
    static let lightPosition: SIMD3<Float> = SIMD3<Float>(1, 2, 1)
    static let lightTarget: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    // MARK: - Animation & Timers
    static let splashScreenDuration: TimeInterval = 2.0
    static let splashScreenFadeDuration: TimeInterval = 0.5
}
