//
//  ARViewContainer.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    var modelURL: URL?
    @Binding var isLoading: Bool
    @Binding var resetTrigger: Bool
    var onPlaced: () -> Void
    var onError: ((Error) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)

        // Setup gestures
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinch)
        
        let rotation = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotation)

        // Setup directional lighting
        let directionalLight = DirectionalLight()
        directionalLight.light.color = .white
        directionalLight.light.intensity = ARConstants.directionalLightIntensity
        directionalLight.light.isRealWorldProxy = false
        directionalLight.look(at: ARConstants.lightTarget, from: ARConstants.lightPosition, relativeTo: nil)
        
        let lightAnchor = AnchorEntity(world: [0, 0, 0])
        lightAnchor.addChild(directionalLight)
        arView.scene.addAnchor(lightAnchor)

        // Load model if URL is present
        guard let url = modelURL else {
            return arView
        }

        context.coordinator.loadCancellable = Entity.loadAsync(contentsOf: url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                self.isLoading = false
                if case let .failure(error) = completion {
                    print("Failed to load 3D model: \(error.localizedDescription)")
                    self.onError?(error)
                }
            }, receiveValue: { loadedEntity in
                loadedEntity.scale = ARConstants.defaultScale
                
                if let modelEntity = loadedEntity as? ModelEntity {
                    modelEntity.generateCollisionShapes(recursive: true)
                }

                context.coordinator.selectedEntity = loadedEntity
                self.isLoading = false
            })

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self
        
        if resetTrigger {
            if let entity = context.coordinator.selectedEntity {
                entity.scale = ARConstants.defaultScale
                entity.orientation = ARConstants.defaultOrientation
            }
            DispatchQueue.main.async {
                resetTrigger = false
            }
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.loadCancellable?.cancel()
        uiView.session.pause()
        uiView.scene.anchors.removeAll()
    }

    class Coordinator: NSObject {
        var parent: ARViewContainer
        var loadCancellable: AnyCancellable?
        
        var selectedEntity: Entity?
        var currentAnchor: AnchorEntity?
        
        var initialScale: SIMD3<Float> = ARConstants.defaultScale
        var initialOrientation: simd_quatf = ARConstants.defaultOrientation

        init(parent: ARViewContainer) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let tapLocation = recognizer.location(in: arView)
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            guard let firstResult = results.first else {
                print("No surface found - point camera at flat surface")
                return
            }

            if let entity = selectedEntity {
                // Remove previous anchor to avoid memory leak and orphan entities
                if let previousAnchor = currentAnchor {
                    arView.scene.removeAnchor(previousAnchor)
                }
                
                let newAnchor = AnchorEntity(world: firstResult.worldTransform)
                entity.removeFromParent()
                newAnchor.addChild(entity)
                arView.scene.addAnchor(newAnchor)
                currentAnchor = newAnchor
                
                parent.onPlaced()
            }
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let _ = recognizer.view as? ARView else { return }
            guard let entity = selectedEntity else { return }
            
            switch recognizer.state {
            case .began:
                initialScale = entity.scale
            case .changed:
                let scale = Float(recognizer.scale)
                let newScale = initialScale * scale
                let clampedScale = SIMD3<Float>(
                    x: max(ARConstants.minScale, min(ARConstants.maxScale, newScale.x)),
                    y: max(ARConstants.minScale, min(ARConstants.maxScale, newScale.y)),
                    z: max(ARConstants.minScale, min(ARConstants.maxScale, newScale.z))
                )
                entity.scale = clampedScale
            case .cancelled:
                entity.scale = initialScale
            default:
                break
            }
        }

        @objc func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
            guard let _ = recognizer.view as? ARView else { return }
            guard let entity = selectedEntity else { return }
            
            switch recognizer.state {
            case .began:
                initialOrientation = entity.orientation
            case .changed:
                let angle = Float(-recognizer.rotation)
                let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
                entity.orientation = initialOrientation * rotation
            case .cancelled:
                entity.orientation = initialOrientation
            default:
                break
            }
        }
    }
}
