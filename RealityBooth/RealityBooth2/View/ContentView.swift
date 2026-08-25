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
                            .background(Color.black.opacity(0.75))
                            .foregroundColor(.white)
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
                            HStack {
                                Image(systemName: selectedModelURL == nil ? "square.and.arrow.up" : "folder.badge.gearshape")
                                Text(selectedModelURL == nil ? "Upload 3D Model" : "Change Model")
                            }
                            .font(.headline)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Reset Button (Only shows after placing model)
                        if isPlaced {
                            Button(action: {
                                resetTrigger = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                                .font(.headline)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
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
                    // Since it returns a single URL, we can pass it directly
                    processSelectedFile(url: url)
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
            
            // --- Splash Screen ---
            // Sits on top of everything else (Z-Index 2)
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
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                Text("Tap any flat surface to place or move the 3D object.")
                    .font(.subheadline)
            }
            
            HStack(spacing: 16) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
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
    // Helper function to safely copy the file from iCloud/Files into the app's local storage
    private func processSelectedFile(url: URL) {
        // We must request security access to read files picked from outside the app
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security scoped resource.")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Create a temporary destination URL inside the app
        let tempDirectory = FileManager.default.temporaryDirectory
        let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            // Remove old file if it exists, then copy the new one
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Update the state variable to trigger the ARView update
            self.isLoading = true // Trigger the loading UI
            self.selectedModelURL = destinationURL
            self.isPlaced = false // Reset placement state for the new model
        } catch {
            print("Error copying file: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
