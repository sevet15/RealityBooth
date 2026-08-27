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
    @State private var deleteTrigger = false
    @State private var clearAllTrigger = false
    
    // Loading & Splash states
    @State private var isLoading = false
    @State private var showSplash = true
    
    // Error handling state
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // --- Main AR Scene ---
            ARViewContainer(
                pendingModel: pendingModel,
                selectedModelId: $selectedModelId,
                isLoading: $isLoading,
                resetTrigger: $resetTrigger,
                deleteTrigger: $deleteTrigger,
                clearAllTrigger: $clearAllTrigger,
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
            .edgesIgnoringSafeArea(.all)
            
            // --- Top HUD Overlay ---
            VStack {
                topHUDBar
                
                instructionBanner
                
                Spacer()
            }
            
            // --- Empty Scene Tutorial Card ---
            if models.isEmpty && pendingModel == nil && !isLoading {
                VStack {
                    Spacer()
                    tutorialCard
                    Spacer()
                }
            }
            
            // --- Bottom Controls Bar ---
            VStack {
                Spacer()
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
            }
            
            // --- Loading Overlay ---
            if isLoading {
                LoadingOverlayView()
            }
            
            // --- Splash Screen ---
            if showSplash {
                SplashScreenView(showSplash: $showSplash)
                    .zIndex(2)
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
            .presentationDetents([.medium])
        }
        .fileImporter(
            isPresented: $showCustomFilePicker,
            allowedContentTypes: [.usdz, .reality]
        ) { result in
            handleCustomFileSelection(result: result)
        }
        .confirmationDialog(
            "Clear All 3D Models?",
            isPresented: $showClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All (\(models.count) Models)", role: .destructive) {
                clearAllModels()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all 3D models from the AR environment.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred.")
        }
    }

    // MARK: - Subviews
    private var topHUDBar: some View {
        HStack {
            // Scene Status Badge
            HStack(spacing: 8) {
                Image(systemName: "cube.transparent.fill")
                    .foregroundColor(.blue)
                Text("\(models.count) / \(ARConstants.maxSimultaneousModels) Models")
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Clear All Button
            if !models.isEmpty {
                Button(action: {
                    showClearAllConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Clear All")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.red)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }

    @ViewBuilder
    private var instructionBanner: some View {
        if let pending = pendingModel {
            Text("Tap on a detected flat surface to place \(pending.name)")
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.9))
                .cornerRadius(12)
                .padding(.top, 8)
                .transition(.scale.combined(with: .opacity))
        } else if let selectedId = selectedModelId, let selected = models.first(where: { $0.id == selectedId }) {
            Text("\(selected.name) selected • Pinch to scale • Twist to rotate • Tap surface to move")
                .font(.caption.bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.top, 8)
                .transition(.opacity)
        }
    }

    private var tutorialCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Multi-Model AR")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 2)
            
            tutorialRow(
                iconName: "plus.circle.fill",
                description: "Tap '+ Add Model' to place up to \(ARConstants.maxSimultaneousModels) 3D objects simultaneously."
            )
            
            tutorialRow(
                iconName: "hand.tap.fill",
                description: "Tap any flat surface to place or tap an existing model to select it."
            )
            
            tutorialRow(
                iconName: "hand.pinch.fill",
                description: "Pinch to resize or twist with two fingers to rotate the selected model."
            )
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal, 24)
        .shadow(radius: 10)
    }

    private func tutorialRow(iconName: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(description)
                .font(.subheadline)
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
                    name: modelName.isEmpty ? "Custom 3D Model" : modelName,
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
        self.deleteTrigger = true
        models.removeAll { $0.id == selectedId }
        self.selectedModelId = nil
    }

    private func clearAllModels() {
        self.clearAllTrigger = true
        models.removeAll()
        self.selectedModelId = nil
        self.pendingModel = nil
    }

    private func showError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}

#Preview {
    ContentView()
}
