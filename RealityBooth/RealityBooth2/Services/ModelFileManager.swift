//
//  ModelFileManager.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import Foundation
import ModelIO
import SceneKit

/// Errors that can occur during 3D model file management
enum ModelFileError: LocalizedError {
    case securityAccessDenied
    case copyFailed(underlyingError: Error)
    case conversionFailed(underlyingError: Error)
    
    var errorDescription: String? {
        switch self {
        case .securityAccessDenied:
            return "Failed to access the selected file. Please grant permission."
        case .copyFailed(let error):
            return "Failed to prepare 3D model: \(error.localizedDescription)"
        case .conversionFailed(let error):
            return "Failed to process 3D model: \(error.localizedDescription)"
        }
    }
}

/// Service responsible for handling security-scoped file access, USDC dependency resolution, and temporary caching of 3D models
struct ModelFileManager {
    /// Copies a security-scoped 3D model URL to a local temporary directory accessible by RealityKit
    /// Automatically converts standalone .usdc files into self-contained .usdz packages to resolve missing scene dependencies
    /// - Parameter sourceURL: The security-scoped URL provided by UIDocumentPicker / fileImporter
    /// - Returns: The destination URL in the temporary directory (converted to .usdz if source was .usdc)
    static func copyToTemporaryDirectory(from sourceURL: URL) throws -> URL {
        guard sourceURL.startAccessingSecurityScopedResource() else {
            throw ModelFileError.securityAccessDenied
        }
        defer {
            sourceURL.stopAccessingSecurityScopedResource()
        }
        
        let fileManager = FileManager.default
        let uniqueFolder = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: uniqueFolder, withIntermediateDirectories: true)
        
        let destinationURL = uniqueFolder.appendingPathComponent(sourceURL.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw ModelFileError.copyFailed(underlyingError: error)
        }
        
        // If file is a standalone .usdc, package/convert it into a self-contained .usdz to eliminate missing dependency errors
        if destinationURL.pathExtension.lowercased() == "usdc" {
            do {
                let usdzURL = uniqueFolder.appendingPathComponent(sourceURL.deletingPathExtension().lastPathComponent).appendingPathExtension("usdz")
                let convertedURL = try convertUSDCToUSDZ(sourceURL: destinationURL, outputURL: usdzURL)
                return convertedURL
            } catch {
                print("USDC conversion notice: \(error.localizedDescription), using original file")
                return destinationURL
            }
        }
        
        return destinationURL
    }
    
    /// Converts a standalone .usdc file into a self-contained .usdz file using ModelIO / SceneKit
    static func convertUSDCToUSDZ(sourceURL: URL, outputURL: URL) throws -> URL {
        // Attempt 1: ModelIO Asset Export (fastest, preserves PBR meshes)
        let asset = MDLAsset(url: sourceURL)
        if MDLAsset.canExportFileExtension("usdz") {
            do {
                try asset.export(to: outputURL)
                if FileManager.default.fileExists(atPath: outputURL.path) {
                    return outputURL
                }
            } catch {
                print("ModelIO export fallback: \(error.localizedDescription)")
            }
        }
        
        // Attempt 2: SceneKit Scene Export fallback
        let scene = try SCNScene(url: sourceURL, options: nil)
        scene.write(to: outputURL, options: nil, delegate: nil, progressHandler: nil)
        return outputURL
    }
}
