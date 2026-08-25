//
//  ARViewContainer.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
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

        // load 3d model
        guard let modelEntity = try? ModelEntity.loadModel(named: "Ferrari") else {
            print("Failed to load 3D model. Check that Enchant.usdz is in your project")
            return arView
        }

        // scale model
        modelEntity.scale = [0.1, 0.1, 0.1]
        modelEntity.generateCollisionShapes(recursive: true)

        // Attempt an initial placement by raycasting from the center of the screen
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let results = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal)
        guard let firstResult = results.first else {
            print("No surface found for initial placement - point camera at a flat surface and tap to place.")
            context.coordinator.selectedEntity = modelEntity
            return arView
        }

        let anchorEntity = AnchorEntity(world: firstResult.worldTransform)
        anchorEntity.addChild(modelEntity)
        arView.scene.addAnchor(anchorEntity)

        context.coordinator.selectedEntity = modelEntity
        print("Placed the model - pinch to scale")

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // empty
    }

    class Coordinator: NSObject {
        var selectedEntity: ModelEntity?
        var initialScale: SIMD3<Float> = [0.1, 0.1, 0.1]
        var initialOrientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])


        let minScale: Float = 0.01
        let maxScale: Float = 1

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
