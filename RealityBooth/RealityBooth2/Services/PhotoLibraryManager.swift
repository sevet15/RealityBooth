//
//  PhotoLibraryManager.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import UIKit

/// Service responsible for saving captured AR snapshot images to the user photo album
final class PhotoLibraryManager: NSObject {
    static let shared = PhotoLibraryManager()
    
    private var completionHandler: ((Result<Void, Error>) -> Void)?
    
    enum PhotoSaveError: LocalizedError {
        case failedToSave(underlying: Error)
        
        var errorDescription: String? {
            switch self {
            case .failedToSave(let underlying):
                return "Failed to save photo to library: \(underlying.localizedDescription)"
            }
        }
    }
    
    func saveImage(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        self.completionHandler = completion
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }
    
    @objc private func image(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        if let error = error {
            completionHandler?(.failure(PhotoSaveError.failedToSave(underlying: error)))
        } else {
            completionHandler?(.success(()))
        }
        completionHandler = nil
    }
}
