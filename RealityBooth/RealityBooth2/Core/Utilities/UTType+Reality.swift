//
//  UTType+Reality.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import UniformTypeIdentifiers

extension UTType {
    /// Uniform Type Identifier for Apple Reality Composer files (.reality)
    static var reality: UTType {
        UTType(filenameExtension: "reality") ?? UTType("com.apple.reality") ?? .data
    }
    
    /// Uniform Type Identifier for USD Binary Crate files (.usdc)
    static var usdc: UTType {
        UTType(filenameExtension: "usdc") ?? UTType("com.pixar.universal-scene-description-mobile") ?? .data
    }
}
