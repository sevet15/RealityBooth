import SwiftUI
import UniformTypeIdentifiers

// Define the custom .reality type for the file picker
extension UTType {
    static var reality: UTType {
        UTType(exportedAs: "com.apple.reality")
    }
}

struct ContentView: View {
    // Application state
    @State private var isShowingFilePicker = false
    @State private var selectedModelURL: URL?
    @State private var isPlaced = false
    @State private var resetTrigger = false
    
    // Loading and Splash screen state
    @State private var isLoading = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            // --- Main App Interface ---
            ZStack {
                // AR View Container
                ARViewContainer(
                    modelURL: selectedModelURL,
                    isLoading: $isLoading,
                    resetTrigger: $resetTrigger,
                    onPlaced: {
                        self.isPlaced = true
                    }
                )
                .edgesIgnoringSafeArea(.all)
                .id(selectedModelURL) // Restarts ARView when URL changes
                
                // --- Overlays ---
                if selectedModelURL == nil {
                    // Show tutorial if no model is selected yet
                    tutorialCard
                } else if !isPlaced && !isLoading {
                    // Show placement instruction after model loads
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
                
                // --- Action Buttons ---
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        // Upload / Change Model Button
                        Button(action: {
                            isShowingFilePicker = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedModelURL == nil ? "square.and.arrow.up" : "folder.fill")
                                    .font(.title2.weight(.medium))
                                Text(selectedModelURL == nil ? "Upload 3D Model" : "Change Model")
                                    .font(.title3.weight(.medium))
                            }
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .foregroundColor(.white)
                            .background(Color(red: 0.0, green: 0.55, blue: 1.0))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(LinearGradient(colors: [.white.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(LinearGradient(colors: [.clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                            )
                            .shadow(color: Color(red: 0.0, green: 0.55, blue: 1.0).opacity(0.5), radius: 10, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        
                        // Reset Button (Only shows after placing model)
                        if isPlaced {
                            Button(action: {
                                resetTrigger = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.title2.weight(.medium))
                                    Text("Reset")
                                        .font(.title3.weight(.medium))
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 16)
                                .foregroundColor(.white)
                                .background(Color(red: 0.9, green: 0.2, blue: 0.2))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(LinearGradient(colors: [.white.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(LinearGradient(colors: [.clear, .black.opacity(0.25)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                                )
                                .shadow(color: Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.5), radius: 10, x: 0, y: 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // --- Loading Overlay ---
                if isLoading {
                    LoadingOverlayView()
                }
            }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: [.usdz, .reality]
            ) { result in
                switch result {
                case .success(let url):
                    processSelectedFile(url: url)
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
            
            // --- Splash Screen ---
            if showSplash {
                SplashScreenView(showSplash: $showSplash)
                    .zIndex(2)
            }
        }
    }
    
    // --- Extracted UI Components ---
    private var tutorialCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How to use AR")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)
            
            HStack(spacing: 16) {
                Image(systemName: "hand.tap.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                Text("Tap any flat surface to place or move the 3D object.")
                    .font(.subheadline)
            }
            
            HStack(spacing: 16) {
                Image(systemName: "hand.pinch.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                Text("Pinch with two fingers to scale the object up and down.")
                    .font(.subheadline)
            }
            
            HStack(spacing: 16) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                Text("Twist with two fingers to rotate the object.")
                    .font(.subheadline)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal, 24)
        .shadow(radius: 10)
    }
    
    // --- Helper Functions ---
    private func processSelectedFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security scoped resource.")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            self.isLoading = true
            self.selectedModelURL = destinationURL
            self.isPlaced = false
        } catch {
            print("Error copying file: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
