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

        // Performance: Optimize render options to eliminate GPU overhead & motion lag
        arView.renderOptions.insert([
            .disableMotionBlur,
            .disableDepthOfField,
            .disableFaceMesh
        ])
        
        // Enable scene understanding physics and lighting
        arView.environment.sceneUnderstanding.options.insert([.receivesLighting])

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

        private func generateThinRingMesh(radius: Float, thickness: Float = 0.020, segments: Int = 64) -> MeshResource? {
            var desc = MeshDescriptor(name: "SelectionOutlineRing")
            var positions: [SIMD3<Float>] = []
            var indices: [UInt32] = []
            
            let innerR = radius
            let outerR = radius + thickness
            
            for i in 0...segments {
                let angle = Float(i) * (2.0 * .pi / Float(segments))
                let cosA = cos(angle)
                let sinA = sin(angle)
                
                positions.append(SIMD3<Float>(innerR * cosA, 0, innerR * sinA))
                positions.append(SIMD3<Float>(outerR * cosA, 0, outerR * sinA))
            }
            
            for i in 0..<segments {
                let v0 = UInt32(i * 2)
                let v1 = UInt32(i * 2 + 1)
                let v2 = UInt32((i + 1) * 2)
                let v3 = UInt32((i + 1) * 2 + 1)
                
                // Double-sided quad rendering so it is 100% visible from all camera angles
                indices.append(contentsOf: [v0, v1, v2, v1, v3, v2])
                indices.append(contentsOf: [v0, v2, v1, v1, v2, v3])
            }
            
            desc.positions = MeshBuffers.Positions(positions)
            desc.primitives = .triangles(indices)
            
            return try? MeshResource.generate(from: [desc])
        }

        func updateSelectionIndicator(for selectedId: UUID?) {
            // 1. Remove previous selection ring from all entities
            for (_, entity) in loadedEntities {
                if let existing = entity.findEntity(named: "SelectionRingIndicator") {
                    existing.removeFromParent()
                }
            }
            
            // 2. Attach bigger prominent 3D outline selection ring centered at the bottom base of the selected model
            guard let selectedId = selectedId, let selectedEntity = loadedEntities[selectedId] else { return }
            
            let bounds = selectedEntity.visualBounds(relativeTo: selectedEntity)
            // 20% smaller radius tailored to frame the model footprint cleanly
            let radius = max(0.30, max(bounds.extents.x, bounds.extents.z) * 0.60)
            
            // Generate a crisp, vibrant blue circular outline ring (16mm stroke line)
            guard let ringMesh = generateThinRingMesh(radius: radius, thickness: 0.016, segments: 64) else { return }
            var material = UnlitMaterial()
            material.color = .init(tint: UIColor(red: 0.0, green: 0.52, blue: 1.0, alpha: 1.0))
            
            let ringEntity = ModelEntity(mesh: ringMesh, materials: [material])
            ringEntity.name = "SelectionRingIndicator"
            
            // Positioned flat on the surface directly at the bottom base footprint of the model (5mm above floor)
            ringEntity.position = SIMD3<Float>(bounds.center.x, bounds.min.y + 0.005, bounds.center.z)
            
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
                    
                    // 2. Measure raw bounds and apply real-world target scale
                    let rawBounds = loadedModel.visualBounds(relativeTo: loadedModel)
                    let extents = rawBounds.extents
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
                    
                    let scaleFactor: Float = maxDim > 0.0001 ? (targetSizeInMeters / maxDim) : 1.0
                    loadedModel.scale = SIMD3<Float>(repeating: scaleFactor)
                    
                    // 3. Add to container first to calculate true compounded visual bounds
                    container.addChild(loadedModel)
                    
                    // 4. Precision Grounding: Calculate exact bounds in container space
                    let boundsInContainer = container.visualBounds(relativeTo: container)
                    
                    // Offset loadedModel so its center sits at (0, 0) in XZ and lowest vertex sits exactly at y = 0
                    loadedModel.position.x -= boundsInContainer.center.x
                    loadedModel.position.y -= boundsInContainer.min.y
                    loadedModel.position.z -= boundsInContainer.center.z
                    
                    // 5. Add a high-performance root box collision component for instant tap hit-testing
                    let finalBounds = container.visualBounds(relativeTo: container)
                    let boxWidth = finalBounds.extents.x
                    let boxHeight = finalBounds.extents.y
                    let boxDepth = finalBounds.extents.z
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

        // MARK: - Native Apple ARKit & LiDAR Multi-Surface (Horizontal & Vertical) Raycasting
        private func performSurfaceRaycast(at point: CGPoint, in arView: ARView) -> simd_float4x4? {
            // 1. Priority 1: Exact physical surface geometry (LiDAR Scene Reconstruction Mesh & ARKit Planes)
            if let result = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .any).first {
                return result.worldTransform
            }
            
            // 2. Priority 2: Infinite plane extension of confirmed detected physical surfaces
            if let result = arView.raycast(from: point, allowing: .existingPlaneInfinite, alignment: .any).first {
                return result.worldTransform
            }
            
            // 3. Priority 3: Estimated surface (Horizontal & Vertical rapid placement)
            if let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first {
                return result.worldTransform
            }
            
            // 4. Priority 4: Native ARKit Hit-Test across detected planes & estimated surfaces
            let planeHits = arView.hitTest(
                point,
                types: [.existingPlaneUsingGeometry, .existingPlaneUsingExtent, .estimatedHorizontalPlane, .estimatedVerticalPlane, .featurePoint]
            )
            if let hit = planeHits.first {
                return hit.worldTransform
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
        
        private var lastPanRaycastTime: TimeInterval = 0

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            guard let selectedId = parent.selectedModelId, let currentAnchor = modelAnchors[selectedId] else { return }
            
            // Performance: Smooth 60FPS throttling for real-time dragging
            let now = CACurrentMediaTime()
            guard now - lastPanRaycastTime >= 0.016 || recognizer.state == .ended else { return }
            lastPanRaycastTime = now
            
            let location = recognizer.location(in: arView)
            guard let worldTransform = performSurfaceRaycast(at: location, in: arView) else { return }
            
            if recognizer.state == .changed || recognizer.state == .ended {
                currentAnchor.setTransformMatrix(worldTransform, relativeTo: nil)
            }
        }
    }
}
