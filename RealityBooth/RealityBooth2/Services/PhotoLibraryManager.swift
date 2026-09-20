//
//  PhotoLibraryManager.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import UIKit
import Photos

/// High-performance asynchronous service responsible for saving captured AR snapshot images using modern Photos framework
final class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()
    
    private init() {}
    
    enum PhotoSaveError: LocalizedError {
        case notAuthorized
        case unknownError
        case underlying(Error)
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Photo library access was not granted. Please enable access in iOS Settings."
            case .unknownError:
                return "An unexpected error occurred while saving the snapshot."
            case .underlying(let error):
                return "Failed to save photo: \(error.localizedDescription)"
            }
        }
    }
    
    /// Pre-warm photo library authorization status on startup
    func prewarm() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in }
    }
    
    /// Asynchronously saves UIImage directly into Photos library using modern Swift concurrency
    func saveImage(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoSaveError.notAuthorized
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    /// Legacy completion handler wrapper for backward compatibility
    func saveImage(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await saveImage(image)
                await MainActor.run {
                    completion(.success(()))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}
