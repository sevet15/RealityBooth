//
//  ModelFileManager.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import Foundation

/// Errors that can occur during 3D model file management
enum ModelFileError: LocalizedError {
    case securityAccessDenied
    case copyFailed(underlyingError: Error)
    
    var errorDescription: String? {
        switch self {
        case .securityAccessDenied:
            return "Failed to access the selected file. Please grant permission."
        case .copyFailed(let error):
            return "Failed to prepare 3D model: \(error.localizedDescription)"
        }
    }
}

/// Service responsible for handling security-scoped file access and temporary caching of 3D models
struct ModelFileManager {
    /// Copies a security-scoped 3D model URL to a local temporary directory accessible by RealityKit
    /// - Parameter sourceURL: The security-scoped URL provided by UIDocumentPicker / fileImporter
    /// - Returns: The destination URL in the temporary directory
    static func copyToTemporaryDirectory(from sourceURL: URL) throws -> URL {
        guard sourceURL.startAccessingSecurityScopedResource() else {
            throw ModelFileError.securityAccessDenied
        }
        defer {
            sourceURL.stopAccessingSecurityScopedResource()
        }
        
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let destinationURL = tempDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            throw ModelFileError.copyFailed(underlyingError: error)
        }
    }
}
