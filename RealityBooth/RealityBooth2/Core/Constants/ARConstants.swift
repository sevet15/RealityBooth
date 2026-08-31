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
    // MARK: - Multi-Model Constraints
    static let maxSimultaneousModels: Int = 4
    
    // MARK: - Scale & Transform
    static let defaultScale: SIMD3<Float> = SIMD3<Float>(1.0, 1.0, 1.0)
    static let minScale: Float = 0.05
    static let maxScale: Float = 5.0
    static let defaultOrientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    
    // MARK: - Selection Indicator
    static let selectionRingRadius: Float = 0.25
    static let selectionRingThickness: Float = 0.015
    
    // MARK: - Soft White Studio Lighting
    static let keyLightIntensity: Float = 4200.0
    static let fillLightIntensity: Float = 2800.0
    static let topLightIntensity: Float = 3200.0
    static let modelPointLightIntensity: Float = 3500.0
    static let keyLightPosition: SIMD3<Float> = SIMD3<Float>(1.2, 3.5, 2.0)
    static let fillLightPosition: SIMD3<Float> = SIMD3<Float>(-1.8, 2.8, 1.5)
    static let topLightPosition: SIMD3<Float> = SIMD3<Float>(0.0, 4.0, 0.2)
    
    // MARK: - Animation & Timers
    static let splashScreenDuration: TimeInterval = 2.0
    static let splashScreenFadeDuration: TimeInterval = 0.5
}
