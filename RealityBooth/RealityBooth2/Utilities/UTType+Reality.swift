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
        UTType(exportedAs: "com.apple.reality")
    }
}
