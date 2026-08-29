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
    var models: [ARModelItem]
    var pendingModel: ARModelItem?
    var selectedModelId: UUID?
    var resetTrigger: Bool
    var takeScreenshotTrigger: Bool
    
    var onModelPlaced: (UUID) -> Void
    var onModelSelected: (UUID) -> Void
    var onModelDeselected: () -> Void
    var onSnapshotCaptured: ((UIImage) -> Void)? = nil
    var onResetHandled: (() -> Void)? = nil
    var onLoadingStateChanged: ((Bool) -> Void)? = nil
    var onError: ((Error) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // MARK: - ARKit Session Configuration with Enhanced LiDAR & Surface Tracking
        let config = ARWorldTrackingConfiguration()
        
        // Enable horizontal and vertical flat surface detection
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        // Auto-focus for sharp feature tracking
        config.isAutoFocusEnabled = true
        
        // Enable LiDAR Scene Reconstruction Mesh when available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        // Enable LiDAR Depth Semantics when supported
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            config.frameSemantics.insert(.smoothedSceneDepth)
        } else if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // Enable scene understanding physics and collision if available
        arView.environment.sceneUnderstanding.options.insert([.collision, .receivesLighting])

        // Setup Gestures
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
        
        // Pre-warm Photo Library permissions & Metal snapshot pipeline in the background
        PhotoLibraryManager.shared.prewarm()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak arView] in
            arView?.snapshot(saveToHDR: false) { _ in }
        }
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self
        
        // 0. Update 3D Selection Highlight in AR Space
        context.coordinator.updateSelectionIndicator(for: selectedModelId)
        
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
                entity.scale = SIMD3<Float>(1, 1, 1)
                entity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            }
            context.coordinator.onResetTriggerHandled()
        }
        
        // 4. Handle Screenshot Capture Trigger
        if takeScreenshotTrigger {
            context.coordinator.captureSnapshot()
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.loadTask?.cancel()
        uiView.session.pause()
        uiView.scene.anchors.removeAll()
    }

    class Coordinator: NSObject {
        var parent: ARViewContainer
        weak var arView: ARView?
        
        var loadTask: Task<Void, Never>?
        var currentLoadingId: UUID?
        var pendingEntity: Entity?
        private var isCapturingSnapshot = false
        
        // Store all placed entities and anchors by model ID
        var loadedEntities: [UUID: Entity] = [:]
        var modelAnchors: [UUID: AnchorEntity] = [:]
        
        // Transform tracking for active gestures
        var initialScale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)
        var initialOrientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])

        init(parent: ARViewContainer) {
            self.parent = parent
        }

        func updateSelectionIndicator(for selectedId: UUID?) {
            // Remove previous selection ring from all models
            for (_, entity) in loadedEntities {
                if let existing = entity.findEntity(named: "SelectionRingIndicator") {
                    existing.removeFromParent()
                }
            }
            
            // Attach 3D selection ring underneath newly selected model
            guard let selectedId = selectedId, let selectedEntity = loadedEntities[selectedId] else { return }
            
            let bounds = selectedEntity.visualBounds(relativeTo: selectedEntity)
            let radius = max(0.18, max(bounds.extents.x, bounds.extents.z) * 0.6)
            
            let ringMesh = MeshResource.generatePlane(width: radius * 2, depth: radius * 2, cornerRadius: radius)
            var material = UnlitMaterial()
            material.color = .init(tint: UIColor.systemBlue.withAlphaComponent(0.6))
            
            let ringEntity = ModelEntity(mesh: ringMesh, materials: [material])
            ringEntity.name = "SelectionRingIndicator"
            ringEntity.position = [0, 0.003, 0] // Just above flat surface plane
            
            selectedEntity.addChild(ringEntity)
        }

        func onResetTriggerHandled() {
            DispatchQueue.main.async { [weak self] in
                self?.parent.onResetHandled?()
            }
        }

        func loadPendingModel(_ modelItem: ARModelItem) {
            currentLoadingId = modelItem.id
            
            loadTask?.cancel()
            loadTask = Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    // Modern iOS 18+ async Entity initialization
                    let loadedModel = try await Entity(contentsOf: modelItem.fileURL)
                    
                    guard !Task.isCancelled else { return }
                    
                    // 1. Create a root pivot container
                    let container = Entity()
                    container.name = modelItem.id.uuidString
                    
                    // 2. Compute local visual bounds (accurate even before scene attachment)
                    let localBounds = loadedModel.visualBounds(relativeTo: loadedModel)
                    let extents = localBounds.extents
                    let maxDim = max(extents.x, max(extents.y, extents.z))
                    
                    // Target real-world scale in meters
                    let targetSizeInMeters: Float
                    if modelItem.name.contains("2") {
                        targetSizeInMeters = 1.0 // Scale Model 2 to exactly 1.0 meter in real world
                    } else if modelItem.name.contains("3") {
                        targetSizeInMeters = 1.0 // Scale Model 3 to 1.0 meter in real world
                    } else {
                        targetSizeInMeters = 0.8 // Standard scale for other models
                    }
                    
                    let scaleFactor: Float
                    if maxDim > 0.0001 {
                        scaleFactor = targetSizeInMeters / maxDim
                    } else {
                        scaleFactor = 1.0
                    }
                    loadedModel.scale = SIMD3<Float>(repeating: scaleFactor)
                    
                    // 3. Ground the model geometry so its bottom (min.y) rests exactly at y = 0
                    let scaledMinY = localBounds.min.y * scaleFactor
                    let scaledCenterX = localBounds.center.x * scaleFactor
                    let scaledCenterZ = localBounds.center.z * scaleFactor
                    
                    loadedModel.position = SIMD3<Float>(-scaledCenterX, -scaledMinY, -scaledCenterZ)
                    container.addChild(loadedModel)
                    
                    // 4. Generate collision shapes on child meshes
                    self.enableCollisionShapes(on: container)
                    
                    // 5. Add a root box collision component to guarantee tap hit testing
                    let boxWidth = max(0.25, extents.x * scaleFactor)
                    let boxHeight = max(0.25, extents.y * scaleFactor)
                    let boxDepth = max(0.25, extents.z * scaleFactor)
                    let boxSize = SIMD3<Float>(boxWidth, boxHeight, boxDepth)
                    let boxCenter = SIMD3<Float>(0, boxHeight / 2.0, 0)
                    
                    container.components[CollisionComponent.self] = CollisionComponent(
                        shapes: [ShapeResource.generateBox(size: boxSize).offsetBy(translation: boxCenter)],
                        mode: .trigger,
                        filter: .default
                    )
                    
                    guard !Task.isCancelled else { return }
                    self.pendingEntity = container
                    self.parent.onLoadingStateChanged?(false)
                    
                } catch {
                    guard !Task.isCancelled else { return }
                    print("Failed to load 3D model \(modelItem.name): \(error.localizedDescription)")
                    self.parent.onLoadingStateChanged?(false)
                    self.parent.onError?(error)
                }
            }
        }
        
        func cancelPendingModel() {
            currentLoadingId = nil
            loadTask?.cancel()
            loadTask = nil
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
        
        func captureSnapshot() {
            guard let arView = arView, !isCapturingSnapshot else { return }
            isCapturingSnapshot = true
            
            arView.snapshot(saveToHDR: false) { [weak self] image in
                guard let self = self else { return }
                self.isCapturingSnapshot = false
                guard let image = image else { return }
                DispatchQueue.main.async {
                    self.parent.onSnapshotCaptured?(image)
                }
            }
        }

        // MARK: - Multi-Surface (Horizontal & Vertical) Raycast with LiDAR & Plane Normalization
        private func normalizeSurfaceTransform(_ transform: simd_float4x4) -> simd_float4x4 {
            let position = simd_make_float3(transform.columns.3)
            let normal = simd_normalize(simd_make_float3(transform.columns.1))
            
            // If surface is horizontal (floor / tabletop), level with gravity
            if abs(normal.y) > 0.65 {
                var forward = simd_make_float3(transform.columns.2)
                forward.y = 0
                if simd_length_squared(forward) < 0.0001 {
                    forward = simd_float3(0, 0, 1)
                } else {
                    forward = simd_normalize(forward)
                }
                let up = simd_float3(0, normal.y >= 0 ? 1 : -1, 0)
                let right = simd_normalize(simd_cross(up, forward))
                
                var result = matrix_identity_float4x4
                result.columns.0 = simd_float4(right.x, right.y, right.z, 0)
                result.columns.1 = simd_float4(up.x, up.y, up.z, 0)
                result.columns.2 = simd_float4(forward.x, forward.y, forward.z, 0)
                result.columns.3 = simd_float4(position.x, position.y, position.z, 1)
                return result
            } else {
                // If surface is vertical (wall / vertical plane), preserve the wall orientation
                return transform
            }
        }

        private func performSurfaceRaycast(at point: CGPoint, in arView: ARView) -> simd_float4x4? {
            // 1. Priority 1: Exact detected plane geometry (Horizontal & Vertical LiDAR mesh / ARKit plane)
            if let result = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .any).first {
                return normalizeSurfaceTransform(result.worldTransform)
            }
            
            // 2. Priority 2: Infinite plane extension of detected horizontal/vertical planes
            if let result = arView.raycast(from: point, allowing: .existingPlaneInfinite, alignment: .any).first {
                return normalizeSurfaceTransform(result.worldTransform)
            }
            
            // 3. Priority 3: Estimated surface (Horizontal & Vertical)
            if let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first {
                return normalizeSurfaceTransform(result.worldTransform)
            }
            
            // 4. Priority 4: Hit-test fallback across horizontal/vertical surfaces and feature points
            let hitResults = arView.hitTest(
                point,
                types: [.existingPlaneUsingGeometry, .existingPlaneUsingExtent, .estimatedHorizontalPlane, .estimatedVerticalPlane, .featurePoint]
            )
            if let hit = hitResults.first {
                return normalizeSurfaceTransform(hit.worldTransform)
            }
            
            return nil
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            // 1. Check if tap hit an existing 3D model entity in the AR scene
            if let hitEntity = arView.entity(at: tapLocation) {
                if let modelId = findModelId(for: hitEntity) {
                    parent.onModelSelected(modelId)
                    return
                }
            }
            
            // 2. Perform multi-priority surface raycast
            guard let worldTransform = performSurfaceRaycast(at: tapLocation, in: arView) else {
                return
            }

            // 3. Place pending model if available
            if let pending = pendingEntity, let modelItem = parent.pendingModel {
                let newAnchor = AnchorEntity(world: worldTransform)
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
            
            // 4. If a model is already selected, tap repositions it to the tapped flat surface
            if let selectedId = parent.selectedModelId, let entity = loadedEntities[selectedId], let currentAnchor = modelAnchors[selectedId] {
                arView.scene.removeAnchor(currentAnchor)
                currentAnchor.removeFromParent()
                
                let newAnchor = AnchorEntity(world: worldTransform)
                entity.removeFromParent()
                newAnchor.addChild(entity)
                arView.scene.addAnchor(newAnchor)
                modelAnchors[selectedId] = newAnchor
                return
            }
            
            // 5. Tap on empty background with no pending model deselects active selection
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
                    x: max(0.05, min(5.0, newScale.x)),
                    y: max(0.05, min(5.0, newScale.y)),
                    z: max(0.05, min(5.0, newScale.z))
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
            guard let worldTransform = performSurfaceRaycast(at: location, in: arView) else { return }
            
            if recognizer.state == .changed {
                currentAnchor.setTransformMatrix(worldTransform, relativeTo: nil)
            }
        }
    }
}
