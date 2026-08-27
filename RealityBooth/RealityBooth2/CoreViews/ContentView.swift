//
//  ContentView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - Multi-Model State Properties
    @State private var models: [ARModelItem] = []
    @State private var pendingModel: ARModelItem?
    @State private var selectedModelId: UUID?
    
    // UI Sheets & Dialogs
    @State private var showModelPicker = false
    @State private var showCustomFilePicker = false
    @State private var showClearAllConfirmation = false
    
    // Triggers for ARViewContainer
    @State private var resetTrigger = false
    
    // Loading & Splash states
    @State private var isLoading = false
    @State private var showSplash = true
    
    // Error handling state
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: - Layer 0: Main AR Scene
            ARViewContainer(
                models: models,
                pendingModel: pendingModel,
                selectedModelId: $selectedModelId,
                isLoading: $isLoading,
                resetTrigger: $resetTrigger,
                onModelPlaced: { placedId in
                    handleModelPlaced(id: placedId)
                },
                onModelSelected: { id in
                    self.selectedModelId = id
                },
                onModelDeselected: {
                    self.selectedModelId = nil
                },
                onError: { error in
                    showError(error.localizedDescription)
                }
            )
            .ignoresSafeArea()
            
            // MARK: - Layer 1: Foreground HUD & Controls
            VStack(spacing: 0) {
                // Top HUD Bar & Instruction Banner
                VStack(spacing: 8) {
                    topHUDBar
                    
                    instructionBanner
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Empty Scene Tutorial Guidance Card
                if models.isEmpty && pendingModel == nil && !isLoading {
                    tutorialCard
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Spacer()
                
                // Bottom Multi-Model Control Platter
                MultiModelControlBar(
                    models: models,
                    selectedModelId: selectedModelId,
                    pendingModel: pendingModel,
                    maxModels: ARConstants.maxSimultaneousModels,
                    onSelectModel: { id in
                        self.selectedModelId = id
                    },
                    onDeselectModel: {
                        self.selectedModelId = nil
                    },
                    onDeleteSelectedModel: {
                        deleteSelectedModel()
                    },
                    onResetSelectedModel: {
                        self.resetTrigger = true
                    },
                    onAddTap: {
                        self.showModelPicker = true
                    },
                    onCancelPending: {
                        self.pendingModel = nil
                    }
                )
                .padding(.bottom, 12)
            }
            
            // MARK: - Layer 2: Loading Overlay
            if isLoading {
                LoadingOverlayView()
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(1)
            }
            
            // MARK: - Layer 3: Splash Screen
            if showSplash {
                SplashScreenView(showSplash: $showSplash)
                    .zIndex(10)
            }
        }
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet(
                currentModelCount: models.count,
                maxModels: ARConstants.maxSimultaneousModels,
                onSelectBuiltIn: { sample in
                    handleSelectBuiltIn(sample: sample)
                },
                onOpenCustomFilePicker: {
                    self.showCustomFilePicker = true
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fileImporter(
            isPresented: $showCustomFilePicker,
            allowedContentTypes: [.usdz, .reality]
        ) { result in
            handleCustomFileSelection(result: result)
        }
        .confirmationDialog(
            "Clear All Models?",
            isPresented: $showClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                clearAllModels()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all 3D models from the AR environment.")
        }
        .alert("Unable to Load Model", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred.")
        }
    }

    // MARK: - Subviews
    private var topHUDBar: some View {
        HStack {
            // Scene Capacity Badge Platter
            HStack(spacing: 8) {
                Image(systemName: "cube.transparent.fill")
                    .foregroundColor(.blue)
                    .font(.subheadline)
                Text("\(models.count) of \(ARConstants.maxSimultaneousModels) Models")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
            
            Spacer()
            
            // Clear All Action Platter
            if !models.isEmpty {
                Button(action: {
                    showClearAllConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Clear All")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.red)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.red.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: 640)
    }

    @ViewBuilder
    private var instructionBanner: some View {
        if let pending = pendingModel {
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.subheadline)
                Text("Tap a flat surface to place \(pending.name)")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue)
            .clipShape(Capsule())
            .shadow(color: Color.blue.opacity(0.35), radius: 10, x: 0, y: 4)
            .transition(.scale.combined(with: .opacity))
        } else if let selectedId = selectedModelId, let selected = models.first(where: { $0.id == selectedId }) {
            Text("\(selected.name) • Drag to move • Pinch to resize • Twist to rotate")
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)
                .transition(.opacity)
        }
    }

    private var tutorialCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Multi-Model AR")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 2)
            
            tutorialRow(
                iconName: "plus.circle.fill",
                title: "Add 3D Models",
                description: "Place up to \(ARConstants.maxSimultaneousModels) models simultaneously into your physical space."
            )
            
            tutorialRow(
                iconName: "hand.tap.fill",
                title: "Detect & Place",
                description: "Point camera at a flat surface and tap to position objects."
            )
            
            tutorialRow(
                iconName: "hand.pinch.fill",
                title: "Transform & Move",
                description: "Drag to reposition, pinch to scale, and twist with two fingers to rotate."
            )
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 24)
        .frame(maxWidth: 440)
    }

    private func tutorialRow(iconName: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Model Placement & Actions
    private func handleSelectBuiltIn(sample: BuiltInModel) {
        guard models.count < ARConstants.maxSimultaneousModels else {
            showError("Maximum capacity reached (\(ARConstants.maxSimultaneousModels) models). Delete a model to add another.")
            return
        }
        
        let filenameComponents = sample.filename.split(separator: ".")
        guard let name = filenameComponents.first,
              let ext = filenameComponents.last,
              let url = Bundle.main.url(forResource: String(name), withExtension: String(ext)) else {
            showError("Could not locate sample 3D model: \(sample.filename)")
            return
        }
        
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

    private func handleCustomFileSelection(result: Result<URL, Error>) {
        guard models.count < ARConstants.maxSimultaneousModels else {
            showError("Maximum capacity reached (\(ARConstants.maxSimultaneousModels) models). Delete a model to add another.")
            return
        }
        
        switch result {
        case .success(let url):
            do {
                let localURL = try ModelFileManager.copyToTemporaryDirectory(from: url)
                let modelName = url.deletingPathExtension().lastPathComponent
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

    private func handleModelPlaced(id: UUID) {
        if var placed = pendingModel, placed.id == id {
            placed.isPlaced = true
            models.append(placed)
            self.selectedModelId = id
            self.pendingModel = nil
        }
    }

    private func deleteSelectedModel() {
        guard let selectedId = selectedModelId else { return }
        withAnimation {
            models.removeAll { $0.id == selectedId }
            self.selectedModelId = nil
        }
    }

    private func clearAllModels() {
        withAnimation {
            models.removeAll()
            self.selectedModelId = nil
            self.pendingModel = nil
        }
    }

    private func showError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}

#Preview {
    ContentView()
}
