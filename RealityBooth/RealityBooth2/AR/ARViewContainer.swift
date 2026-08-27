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
    var models: [ARModelItem]
    var pendingModel: ARModelItem?
    @Binding var selectedModelId: UUID?
    @Binding var isLoading: Bool
    @Binding var resetTrigger: Bool
    
    var onModelPlaced: (UUID) -> Void
    var onModelSelected: (UUID) -> Void
    var onModelDeselected: () -> Void
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
        
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(pan)

        // Setup directional lighting
        let directionalLight = DirectionalLight()
        directionalLight.light.color = .white
        directionalLight.light.intensity = ARConstants.directionalLightIntensity
        directionalLight.light.isRealWorldProxy = false
        directionalLight.look(at: ARConstants.lightTarget, from: ARConstants.lightPosition, relativeTo: nil)
        
        let lightAnchor = AnchorEntity(world: [0, 0, 0])
        lightAnchor.addChild(directionalLight)
        arView.scene.addAnchor(lightAnchor)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self
        
        // 1. Sync removed models: remove anchors and entities for any models no longer in `models`
        let activeModelIds = Set(models.map { $0.id })
        let currentAnchoredIds = Array(context.coordinator.modelAnchors.keys)
        for existingId in currentAnchoredIds {
            if !activeModelIds.contains(existingId) {
                context.coordinator.removeModel(id: existingId)
            }
        }
        
        // 2. Handle pending model loading or cancellation
        if let pending = pendingModel {
            if context.coordinator.currentLoadingId != pending.id && context.coordinator.loadedEntities[pending.id] == nil {
                context.coordinator.loadPendingModel(pending)
            }
        } else {
            context.coordinator.cancelPendingModel()
        }
        
        // 3. Handle Reset Transform Trigger
        if resetTrigger {
            if let selectedId = selectedModelId, let entity = context.coordinator.loadedEntities[selectedId] {
                entity.scale = ARConstants.defaultScale
                entity.orientation = ARConstants.defaultOrientation
            }
            DispatchQueue.main.async {
                self.resetTrigger = false
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
        weak var arView: ARView?
        
        var loadCancellable: AnyCancellable?
        var currentLoadingId: UUID?
        var pendingEntity: Entity?
        
        // Store all placed entities and anchors by model ID
        var loadedEntities: [UUID: Entity] = [:]
        var modelAnchors: [UUID: AnchorEntity] = [:]
        
        // Transform tracking for active gestures
        var initialScale: SIMD3<Float> = ARConstants.defaultScale
        var initialOrientation: simd_quatf = ARConstants.defaultOrientation

        init(parent: ARViewContainer) {
            self.parent = parent
        }

        func loadPendingModel(_ modelItem: ARModelItem) {
            currentLoadingId = modelItem.id
            parent.isLoading = true
            
            loadCancellable?.cancel()
            loadCancellable = Entity.loadAsync(contentsOf: modelItem.fileURL)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.parent.isLoading = false
                    if case let .failure(error) = completion {
                        print("Failed to load 3D model \(modelItem.name): \(error.localizedDescription)")
                        self.parent.onError?(error)
                    }
                }, receiveValue: { [weak self] loadedEntity in
                    guard let self = self else { return }
                    loadedEntity.name = modelItem.id.uuidString
                    loadedEntity.scale = ARConstants.defaultScale
                    
                    // Enable collision shapes for hit testing and gesture manipulation
                    self.enableCollisionShapes(on: loadedEntity)
                    
                    self.pendingEntity = loadedEntity
                    self.parent.isLoading = false
                })
        }
        
        func cancelPendingModel() {
            currentLoadingId = nil
            loadCancellable?.cancel()
            loadCancellable = nil
            pendingEntity?.removeFromParent()
            pendingEntity = nil
        }
        
        private func enableCollisionShapes(on entity: Entity) {
            if let model = entity as? ModelEntity {
                model.generateCollisionShapes(recursive: true)
            }
            for child in entity.children {
                enableCollisionShapes(on: child)
            }
        }
        
        func removeModel(id: UUID) {
            if let anchor = modelAnchors[id] {
                anchor.children.removeAll()
                arView?.scene.removeAnchor(anchor)
                anchor.removeFromParent()
            }
            if let entity = loadedEntities[id] {
                entity.removeFromParent()
            }
            modelAnchors.removeValue(forKey: id)
            loadedEntities.removeValue(forKey: id)
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            // 1. Check if tap hit an existing model entity in AR scene
            if let hitEntity = arView.entity(at: tapLocation) {
                if let modelId = findModelId(for: hitEntity) {
                    parent.onModelSelected(modelId)
                    return
                }
            }
            
            // 2. Perform surface raycast
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            guard let firstResult = results.first else {
                return
            }

            // 3. Place pending model if available
            if let pending = pendingEntity, let modelItem = parent.pendingModel {
                let newAnchor = AnchorEntity(world: firstResult.worldTransform)
                pending.removeFromParent()
                newAnchor.addChild(pending)
                arView.scene.addAnchor(newAnchor)
                
                modelAnchors[modelItem.id] = newAnchor
                loadedEntities[modelItem.id] = pending
                
                self.pendingEntity = nil
                self.currentLoadingId = nil
                
                parent.onModelPlaced(modelItem.id)
                return
            }
            
            // 4. If a model is already selected, tap moves it to the new location
            if let selectedId = parent.selectedModelId, let entity = loadedEntities[selectedId], let currentAnchor = modelAnchors[selectedId] {
                arView.scene.removeAnchor(currentAnchor)
                currentAnchor.removeFromParent()
                
                let newAnchor = AnchorEntity(world: firstResult.worldTransform)
                entity.removeFromParent()
                newAnchor.addChild(entity)
                arView.scene.addAnchor(newAnchor)
                modelAnchors[selectedId] = newAnchor
                return
            }
            
            // 5. Tap on empty background with no pending model deselects
            parent.onModelDeselected()
        }
        
        private func findModelId(for entity: Entity) -> UUID? {
            var current: Entity? = entity
            while let node = current {
                if let uuid = UUID(uuidString: node.name), loadedEntities[uuid] != nil {
                    return uuid
                }
                current = node.parent
            }
            return nil
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let selectedId = parent.selectedModelId, let entity = loadedEntities[selectedId] else { return }
            
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
            guard let selectedId = parent.selectedModelId, let entity = loadedEntities[selectedId] else { return }
            
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
        
        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            guard let selectedId = parent.selectedModelId, let currentAnchor = modelAnchors[selectedId] else { return }
            
            let location = recognizer.location(in: arView)
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            guard let firstResult = results.first else { return }
            
            if recognizer.state == .changed {
                currentAnchor.setTransformMatrix(firstResult.worldTransform, relativeTo: nil)
            }
        }
    }
}
