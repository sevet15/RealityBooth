//
//  ARViewContainer.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI
import RealityKit
import ARKit
import Combine // Added to support async loading

struct ARViewContainer: UIViewRepresentable {
    // Add a variable to accept the uploaded file URL
    var modelURL: URL?
    @Binding var isLoading: Bool // Added binding to communicate loading state back
    @Binding var resetTrigger: Bool
    var onPlaced: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        // Enable automatic environment texturing for realistic lighting and reflections
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)

        // Add gestures routed to coordinator
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinch)
        let rotation = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotation)

        // Add an extra directional light to ensure the object is never too dark
        let directionalLight = DirectionalLight()
        directionalLight.light.color = .white
        directionalLight.light.intensity = 1500
        directionalLight.light.isRealWorldProxy = false
        directionalLight.look(at: [0, 0, 0], from: [1, 2, 1], relativeTo: nil)
        let lightAnchor = AnchorEntity(world: [0, 0, 0])
        lightAnchor.addChild(directionalLight)
        arView.scene.addAnchor(lightAnchor)

        // Only attempt to load if a URL is provided
        guard let url = modelURL else {
            print("No model uploaded yet. Waiting for user to select a file.")
            return arView
        }

        // Load 3D model asynchronously to prevent freezing the UI and allow loading screen to show
        context.coordinator.loadCancellable = Entity.loadAsync(contentsOf: url)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Failed to load 3D model: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }, receiveValue: { loadedEntity in
                // scale model
                loadedEntity.scale = [0.1, 0.1, 0.1]
                
                // Generate collision shapes safely if it is a ModelEntity (.usdz usually is)
                if let modelEntity = loadedEntity as? ModelEntity {
                    modelEntity.generateCollisionShapes(recursive: true)
                }

                // Store the loaded entity, but wait for the user to tap to place it
                context.coordinator.selectedEntity = loadedEntity
                print("Model loaded. Waiting for user to tap to place.")
                
                // Hide the loading overlay now that it's ready
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            })

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Handle reset trigger
        if resetTrigger {
            if let entity = context.coordinator.selectedEntity {
                entity.scale = [0.1, 0.1, 0.1]
                entity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
                print("Reset 3D object to starting scale and rotation")
            }
            // Asynchronously reset the trigger to avoid state update warnings
            DispatchQueue.main.async {
                resetTrigger = false
            }
        }
    }

    class Coordinator: NSObject {
        var parent: ARViewContainer
        var loadCancellable: AnyCancellable? // Holds the async load stream
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        // Change from ModelEntity to Entity to support both USDZ and Reality scenes
        var selectedEntity: Entity?
        var initialScale: SIMD3<Float> = [0.1, 0.1, 0.1]
        var initialOrientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])


        let minScale: Float = 0.001
        let maxScale: Float = 2

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let tapLocation = recognizer.location(in: arView)
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            guard let firstResult = results.first else {
                print("No surface was found - point camera at flat surface")
                return
            }

            // If we already have a selected entity, move it to the new anchor; otherwise, nothing to place
            if let entity = selectedEntity {
                let newAnchor = AnchorEntity(world: firstResult.worldTransform)
                // Remove from previous parent if any and reparent to new anchor
                entity.removeFromParent()
                newAnchor.addChild(entity)
                arView.scene.addAnchor(newAnchor)
                print("Moved model to new location")
                
                // Notify parent that placement was successful
                parent.onPlaced()
            }
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let _ = recognizer.view as? ARView else { return }
            guard let entity = selectedEntity else {
                print("No entity is selected tap to place an object first")
                return
            }
            switch recognizer.state {
            case .began:
                initialScale = entity.scale
                print("Started scaling from \(initialScale)")
            case .changed:
                let scale = Float(recognizer.scale)
                let newScale = initialScale * scale
                let clampedScale = SIMD3<Float>(
                    x: max(minScale, min(maxScale, newScale.x)),
                    y: max(minScale, min(maxScale, newScale.y)),
                    z: max(minScale, min(maxScale, newScale.z))
                )
                entity.scale = clampedScale
            case .ended:
                print("Final scale \(entity.scale)")
            case .cancelled:
                entity.scale = initialScale
                print("Scale cancelled")
            default:
                break
            }
        }

        @objc func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
            guard let _ = recognizer.view as? ARView else { return }
            guard let entity = selectedEntity else {
                print("No entity is selected tap to place an object first")
                return
            }
            switch recognizer.state {
            case .began:
                initialOrientation = entity.orientation
                print("Started rotating from \(initialOrientation)")
            case .changed:
                // UIRotationGestureRecognizer's rotation is in radians, screen-space (clockwise positive).
                // We rotate around the world/local Y axis so the object spins like a turntable.
                let angle = Float(-recognizer.rotation)
                let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
                entity.orientation = initialOrientation * rotation
            case .ended:
                print("Final orientation \(entity.orientation)")
            case .cancelled:
                entity.orientation = initialOrientation
                print("Rotation cancelled")
            default:
                break
            }
        }
    }
}
