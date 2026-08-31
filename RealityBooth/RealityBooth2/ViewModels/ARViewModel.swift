//
//  ARViewModel.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI
import Combine

/// Central ViewModel managing all AR state, multi-model lifecycle, and optimized photo capture workflows
@MainActor
final class ARViewModel: ObservableObject {
    // MARK: - Published State Properties
    @Published var models: [ARModelItem] = []
    @Published var pendingModel: ARModelItem?
    @Published var selectedModelId: UUID?
    
    // UI Sheets & Dialogs
    @Published var showModelPicker: Bool = false
    @Published var showCustomFilePicker: Bool = false
    @Published var showClearAllConfirmation: Bool = false
    
    // Scale Percentage & Live Dimension Feedback (in cm)
    @Published var scalePercentage: Int? = nil
    @Published var scaleDimensionsCm: SIMD3<Int>? = nil
    @Published var scaleBadgePosition: CGPoint? = nil
    private var scaleDismissTimer: Task<Void, Never>?

    // Triggers for ARView Container
    @Published var resetTrigger: Bool = false
    @Published var takeScreenshotTrigger: Bool = false
    
    // Visual Feedback States
    @Published var showShutterFlash: Bool = false
    @Published var showScreenshotSavedToast: Bool = false
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = "Loading 3D Model…"
    @Published var showSplash: Bool = true
    
    // Error Handling
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    // Private concurrency guard
    private var isCapturingSnapshot = false
    
    // MARK: - Computed Helpers
    var isMaxCapacityReached: Bool {
        models.count >= ARConstants.maxSimultaneousModels
    }
    
    var selectedModel: ARModelItem? {
        guard let id = selectedModelId else { return nil }
        return models.first(where: { $0.id == id })
    }
    
    // MARK: - Model Placement Workflow
    func selectModel(id: UUID) {
        self.selectedModelId = id
    }
    
    func deselectModel() {
        self.selectedModelId = nil
    }
    
    func startPlacing(sample: BuiltInModel) {
        guard !isMaxCapacityReached else {
            showError("Maximum capacity reached (\(ARConstants.maxSimultaneousModels) models). Delete a model to add another.")
            return
        }
        
        let filenameComponents = sample.filename.split(separator: ".")
        guard let name = filenameComponents.first,
              let ext = filenameComponents.last else {
            showError("Could not locate sample 3D model: \(sample.filename)")
            return
        }
        
        // Robust multi-extension bundle lookup (.usdz, .usdc, .reality)
        var modelURL = Bundle.main.url(forResource: String(name), withExtension: String(ext))
        if modelURL == nil {
            modelURL = Bundle.main.url(forResource: String(name), withExtension: "usdz")
        }
        if modelURL == nil {
            modelURL = Bundle.main.url(forResource: String(name), withExtension: "usdc")
        }
        if modelURL == nil {
            modelURL = Bundle.main.url(forResource: String(name), withExtension: "reality")
        }
        
        guard let url = modelURL else {
            showError("Could not locate sample 3D model: \(sample.filename)")
            return
        }
        
        loadingMessage = "Loading \(sample.name)…"
        let newItem = ARModelItem(
            name: sample.name,
            fileURL: url,
            isBuiltIn: true,
            isPlaced: false,
            systemIcon: sample.systemIcon
        )
        self.pendingModel = newItem
        self.selectedModelId = nil
    }
    
    func startPlacingCustom(result: Result<URL, Error>) {
        guard !isMaxCapacityReached else {
            showError("Maximum capacity reached (\(ARConstants.maxSimultaneousModels) models). Delete a model to add another.")
            return
        }
        
        switch result {
        case .success(let url):
            do {
                let localURL = try ModelFileManager.copyToTemporaryDirectory(from: url)
                let modelName = url.deletingPathExtension().lastPathComponent
                loadingMessage = "Loading \(modelName)…"
                let newItem = ARModelItem(
                    name: modelName.isEmpty ? "Custom Model" : modelName,
                    fileURL: localURL,
                    isBuiltIn: false,
                    isPlaced: false,
                    systemIcon: "cube.fill"
                )
                self.pendingModel = newItem
                self.selectedModelId = nil
            } catch {
                showError(error.localizedDescription)
            }
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }
    
    func confirmPlacement(id: UUID) {
        if var placed = pendingModel, placed.id == id {
            placed.isPlaced = true
            models.append(placed)
            self.selectedModelId = id
            self.pendingModel = nil
        }
    }
    
    func cancelPendingPlacement() {
        self.pendingModel = nil
    }
    
    func deleteSelectedModel() {
        guard let selectedId = selectedModelId else { return }
        withAnimation {
            models.removeAll { $0.id == selectedId }
            self.selectedModelId = nil
        }
    }
    
    func updateScalePercentage(_ percentage: Int, dimensionsCm: SIMD3<Int>?, screenPoint: CGPoint?) {
        scaleDismissTimer?.cancel()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            self.scalePercentage = percentage
            self.scaleDimensionsCm = dimensionsCm
            if let point = screenPoint {
                self.scaleBadgePosition = point
            }
        }
    }
    
    func endScaleInteraction() {
        scaleDismissTimer?.cancel()
        scaleDismissTimer = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                self.scalePercentage = nil
                self.scaleDimensionsCm = nil
            }
        }
    }

    func resetSelectedModel() {
        guard selectedModelId != nil, !resetTrigger else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.1)) {
            self.isLoading = true
            self.loadingMessage = "Resetting Model…"
        }
        
        self.resetTrigger = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                self.isLoading = false
                self.loadingMessage = "Loading 3D Model…"
            }
        }
    }
    
    func clearAllModels() {
        loadingMessage = "Clearing 3D Models…"
        withAnimation {
            isLoading = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation {
                self.models.removeAll()
                self.selectedModelId = nil
                self.pendingModel = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    self.isLoading = false
                    self.loadingMessage = "Loading 3D Model…"
                }
            }
        }
    }
    
    // MARK: - Optimized Screenshot Capture Workflow
    func triggerScreenshot() {
        // Prevent concurrent overload
        guard !isCapturingSnapshot else { return }
        isCapturingSnapshot = true
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        loadingMessage = "Capturing Photo…"
        withAnimation(.easeInOut(duration: 0.15)) {
            isLoading = true
            showShutterFlash = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.showShutterFlash = false
            }
        }
        
        self.takeScreenshotTrigger = true
    }
    
    func handleSnapshotCaptured(_ image: UIImage) {
        PhotoLibraryManager.shared.saveImage(image) { [weak self] result in
            guard let self = self else { return }
            self.isCapturingSnapshot = false
            
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isLoading = false
                self.loadingMessage = "Loading 3D Model…"
            }
            
            switch result {
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.showScreenshotSavedToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.showScreenshotSavedToast = false
                    }
                }
            case .failure(let error):
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                self.showError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Error Handling
    func showError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}

