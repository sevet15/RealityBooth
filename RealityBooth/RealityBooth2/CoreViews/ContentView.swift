//
//  ContentView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// Root AR View composing the scene, HUD layers, controls, and dialogs using MVVM architecture
struct ContentView: View {
    @StateObject private var viewModel = ARViewModel()

    var body: some View {
        ZStack {
            // MARK: - Layer 0: Main AR Scene
            ARViewContainer(
                models: viewModel.models,
                pendingModel: viewModel.pendingModel,
                selectedModelId: $viewModel.selectedModelId,
                isLoading: $viewModel.isLoading,
                resetTrigger: $viewModel.resetTrigger,
                takeScreenshotTrigger: $viewModel.takeScreenshotTrigger,
                onModelPlaced: { placedId in
                    viewModel.confirmPlacement(id: placedId)
                },
                onModelSelected: { id in
                    viewModel.selectModel(id: id)
                },
                onModelDeselected: {
                    viewModel.deselectModel()
                },
                onSnapshotCaptured: { image in
                    viewModel.handleSnapshotCaptured(image)
                },
                onError: { error in
                    viewModel.showError(error.localizedDescription)
                }
            )
            .ignoresSafeArea()
            
            // MARK: - Layer 1: Foreground HUD & Controls
            VStack(spacing: 0) {
                // Top HUD & Dynamic Context Banner
                VStack(spacing: 10) {
                    TopHUDBarView(viewModel: viewModel)
                    
                    InstructionBannerView(viewModel: viewModel)
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Empty Scene Tutorial Card
                if viewModel.models.isEmpty && viewModel.pendingModel == nil && !viewModel.isLoading {
                    TutorialCardView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Spacer()
                
                // Bottom Area: Camera Shutter & Multi-Model Toolbar
                VStack(spacing: 12) {
                    if !viewModel.models.isEmpty && viewModel.pendingModel == nil {
                        ShutterButtonView(viewModel: viewModel)
                    }
                    
                    MultiModelControlBar(
                        models: viewModel.models,
                        selectedModelId: viewModel.selectedModelId,
                        pendingModel: viewModel.pendingModel,
                        maxModels: ARConstants.maxSimultaneousModels,
                        onSelectModel: { id in viewModel.selectModel(id: id) },
                        onDeselectModel: { viewModel.deselectModel() },
                        onDeleteSelectedModel: { viewModel.deleteSelectedModel() },
                        onResetSelectedModel: { viewModel.resetSelectedModel() },
                        onAddTap: { viewModel.showModelPicker = true },
                        onCancelPending: { viewModel.cancelPendingPlacement() }
                    )
                }
                .padding(.bottom, 12)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.models.isEmpty)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.pendingModel)
            }
            
            // MARK: - Layer 2: Loading Overlay
            if viewModel.isLoading {
                LoadingOverlayView(message: viewModel.loadingMessage)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(1)
            }
            
            // MARK: - Layer 3: Splash Screen
            if viewModel.showSplash {
                SplashScreenView(showSplash: $viewModel.showSplash)
                    .zIndex(10)
            }
            
            // MARK: - Layer 4: Shutter Flash Effect
            if viewModel.showShutterFlash {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.85)
                    .transition(.opacity)
                    .zIndex(20)
            }
            
            // MARK: - Layer 5: Snapshot Saved Toast
            if viewModel.showScreenshotSavedToast {
                ToastNotificationView()
                    .zIndex(25)
            }
        }
        .sheet(isPresented: $viewModel.showModelPicker) {
            ModelPickerSheet(
                currentModelCount: viewModel.models.count,
                maxModels: ARConstants.maxSimultaneousModels,
                onSelectBuiltIn: { sample in
                    viewModel.startPlacing(sample: sample)
                },
                onOpenCustomFilePicker: {
                    viewModel.showCustomFilePicker = true
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fileImporter(
            isPresented: $viewModel.showCustomFilePicker,
            allowedContentTypes: [.usdz, .reality]
        ) { result in
            viewModel.startPlacingCustom(result: result)
        }
        .confirmationDialog(
            "Clear All Models?",
            isPresented: $viewModel.showClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.clearAllModels()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all 3D models from the AR environment.")
        }
        .alert("Unable to Complete Action", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unexpected error occurred.")
        }
    }
}

#Preview {
    ContentView()
}
