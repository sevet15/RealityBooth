//
//  ContentView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - State Properties
    @State private var isShowingFilePicker = false
    @State private var selectedModelURL: URL?
    @State private var isPlaced = false
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
            // --- Main AR Interface ---
            ZStack {
                ARViewContainer(
                    modelURL: selectedModelURL,
                    isLoading: $isLoading,
                    resetTrigger: $resetTrigger,
                    onPlaced: {
                        self.isPlaced = true
                    },
                    onError: { error in
                        showError(error.localizedDescription)
                    }
                )
                .edgesIgnoringSafeArea(.all)
                .id(selectedModelURL) // Restarts ARView when model URL changes
                
                // --- Overlays ---
                if selectedModelURL == nil {
                    tutorialCard
                } else if !isPlaced && !isLoading {
                    placementInstructionOverlay
                }
                
                // --- Action Controls ---
                actionButtonsOverlay
                
                // --- Loading Overlay ---
                if isLoading {
                    LoadingOverlayView()
                }
            }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [.usdz, .reality]
            ) { result in
                handleFileSelection(result: result)
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unexpected error occurred.")
            }
            
            // --- Splash Screen ---
            if showSplash {
                SplashScreenView(showSplash: $showSplash)
                    .zIndex(2)
            }
        }
    }

    // MARK: - Subviews
    private var placementInstructionOverlay: some View {
        VStack {
            Text("Tap on a flat surface to place the 3D model")
                .font(.headline)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.top, 40)
            
            Spacer()
        }
    }

    private var actionButtonsOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 20) {
                // Upload / Change Model Button
                Button(action: {
                    isShowingFilePicker = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: selectedModelURL == nil ? "square.and.arrow.up" : "folder.fill")
                        Text(selectedModelURL == nil ? "Upload 3D Model" : "Change Model")
                    }
                }
                .buttonStyle(CapsuleActionButtonStyle(backgroundColor: Color(red: 0.0, green: 0.55, blue: 1.0)))
                
                // Reset Button
                if isPlaced {
                    Button(action: {
                        resetTrigger = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                    }
                    .buttonStyle(CapsuleActionButtonStyle(backgroundColor: Color(red: 0.9, green: 0.2, blue: 0.2)))
                }
            }
            .padding(.bottom, 40)
        }
    }

    private var tutorialCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How to use AR")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)
            
            tutorialRow(
                iconName: "hand.tap.fill",
                description: "Tap any flat surface to place or move the 3D object."
            )
            
            tutorialRow(
                iconName: "hand.pinch.fill",
                description: "Pinch with two fingers to scale the object up and down."
            )
            
            tutorialRow(
                iconName: "arrow.triangle.2.circlepath",
                description: "Twist with two fingers to rotate the object."
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

    // MARK: - Actions & File Handling
    private func handleFileSelection(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let localURL = try ModelFileManager.copyToTemporaryDirectory(from: url)
                self.isLoading = true
                self.selectedModelURL = localURL
                self.isPlaced = false
            } catch {
                showError(error.localizedDescription)
            }
        case .failure(let error):
            showError(error.localizedDescription)
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
