//
//  ARViewContainer.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI
import RealityKit
import ARKit

/// SwiftUI wrapper for RealityKit's ARView managing multi-model lifecycle, LiDAR tracking, and gestures
struct ARViewContainer: UIViewRepresentable {
    // MARK: - Properties
    let models: [ARModelItem]
    let pendingModel: ARModelItem?
    let selectedModelId: UUID?
    let resetTrigger: Bool
    let takeScreenshotTrigger: Bool
    
    // Callbacks
    let onModelPlaced: (UUID) -> Void
    let onModelSelected: (UUID) -> Void
    let onModelDeselected: () -> Void
    var onSnapshotCaptured: ((UIImage) -> Void)? = nil
    var onResetHandled: (() -> Void)? = nil
    var onLoadingStateChanged: ((Bool) -> Void)? = nil
    var onScaleChanged: ((Int, SIMD3<Int>, CGPoint?) -> Void)? = nil
    var onScaleEnded: (() -> Void)? = nil
    var onError: ((Error) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // MARK: - Thermal & Power Optimized ARKit Session Configuration
        let config = ARWorldTrackingConfiguration()
        
        // 1. Efficient 1080p Video Format to prevent camera ISP overheating
        if let optimalFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: {
            $0.imageResolution.height == 1080 && $0.framesPerSecond == 60
        }) ?? ARWorldTrackingConfiguration.supportedVideoFormats.first(where: {
            $0.imageResolution.height <= 1080
        }) {
            config.videoFormat = optimalFormat
        }
        
        // 2. Enable horizontal and vertical flat surface detection
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        config.isAutoFocusEnabled = true
        
        // 3. Thermal Optimization: Use lightweight LiDAR Mesh without heavy CoreML classification loops
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        // 4. Single stabilized depth semantic stream to reduce Neural Engine temperature
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            config.frameSemantics.insert(.smoothedSceneDepth)
        }
        
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        // 5. Thermal & GPU Power Optimization: Disable energy-draining post-processing
        arView.renderOptions.insert([
            .disableMotionBlur,
            .disableDepthOfField,
            .disableFaceMesh,
            .disablePersonOcclusion
        ])
        
        // Lighting only (avoids continuous background physics solver loops)
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

        context.coordinator.arView = arView
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
        
        // 3. Handle Reset Transform Trigger (100% Real Size Base: scale = 1.0)
        if resetTrigger {
            if let selectedId = selectedModelId, let entity = context.coordinator.loadedEntities[selectedId] {
                entity.scale = SIMD3<Float>(1, 1, 1)
                entity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
                context.coordinator.initialScale = SIMD3<Float>(1, 1, 1)
                context.coordinator.initialOrientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            }
            context.coordinator.onResetTriggerHandled()
        }
        
        // 4. Handle Snapshot Capture Trigger
        if takeScreenshotTrigger {
            context.coordinator.captureSnapshot()
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject {
        var parent: ARViewContainer
        weak var arView: ARView?
        
        // Multi-Model storage: Maps Model ID to AnchorEntity and loaded root Entity
        var modelAnchors: [UUID: AnchorEntity] = [:]
        var loadedEntities: [UUID: Entity] = [:]
        
        // Loading state
        var currentLoadingId: UUID?
        var pendingEntity: Entity?
        private var loadTask: Task<Void, Never>?
        private var isCapturingSnapshot = false
        private var lastPanRaycastTime: TimeInterval = 0
        
        // Gesture transforms tracking
        var initialScale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)
        var initialOrientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])

        init(parent: ARViewContainer) {
            self.parent = parent
        }

        func updateSelectionIndicator(for selectedId: UUID?) {
            // 1. Remove previous selection ring from all entities
            for (_, entity) in loadedEntities {
                if let existing = entity.findEntity(named: ARSelectionIndicator.indicatorName) {
                    existing.removeFromParent()
                }
            }
            
            // 2. Attach 3D outline selection ring centered at the bottom base of the selected model
            guard let selectedId = selectedId, let selectedEntity = loadedEntities[selectedId] else { return }
            guard let ringEntity = ARSelectionIndicator.createIndicatorEntity(for: selectedEntity) else { return }
            selectedEntity.addChild(ringEntity)
        }

        func onResetTriggerHandled() {
            DispatchQueue.main.async { [weak self] in
                self?.parent.onResetHandled?()
            }
        }

        func loadPendingModel(_ modelItem: ARModelItem) {
            loadTask?.cancel()
            currentLoadingId = modelItem.id
            parent.onLoadingStateChanged?(true)
            
            loadTask = Task { @MainActor [weak self] in
                guard let self = self else { return }
                do {
                    // Modern iOS 18+ async Entity initialization with USDC dependency resolution fallback
                    var loadedModel: Entity
                    do {
                        loadedModel = try await Entity(contentsOf: modelItem.fileURL)
                    } catch {
                        if modelItem.fileURL.pathExtension.lowercased() == "usdc" || error.localizedDescription.lowercased().contains("dependenc") {
                            let usdzURL = modelItem.fileURL.deletingPathExtension().appendingPathExtension("usdz")
                            let convertedURL = try ModelFileManager.convertUSDCToUSDZ(sourceURL: modelItem.fileURL, outputURL: usdzURL)
                            loadedModel = try await Entity(contentsOf: convertedURL)
                        } else {
                            throw error
                        }
                    }
                    
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
            guard let worldTransform = ARSurfaceManager.performSurfaceRaycast(at: tapLocation, in: arView) else {
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
            guard let arView = recognizer.view as? ARView else { return }
            guard let selectedId = parent.selectedModelId, let entity = loadedEntities[selectedId] else { return }
            
            let bounds = entity.visualBounds(relativeTo: entity)

            switch recognizer.state {
            case .began:
                initialScale = entity.scale
                let percentage = Int(round(entity.scale.x * 100))
                let dims = SIMD3<Int>(
                    max(1, Int(round(bounds.extents.x * entity.scale.x * 100.0))),
                    max(1, Int(round(bounds.extents.y * entity.scale.y * 100.0))),
                    max(1, Int(round(bounds.extents.z * entity.scale.z * 100.0)))
                )
                let screenPoint = arView.project(entity.position(relativeTo: nil))
                parent.onScaleChanged?(percentage, dims, screenPoint)
            case .changed:
                let scale = Float(recognizer.scale)
                let newScale = initialScale * scale
                let clampedScale = SIMD3<Float>(
                    x: max(0.05, min(5.0, newScale.x)),
                    y: max(0.05, min(5.0, newScale.y)),
                    z: max(0.05, min(5.0, newScale.z))
                )
                entity.scale = clampedScale
                let percentage = Int(round(clampedScale.x * 100))
                let dims = SIMD3<Int>(
                    max(1, Int(round(bounds.extents.x * clampedScale.x * 100.0))),
                    max(1, Int(round(bounds.extents.y * clampedScale.y * 100.0))),
                    max(1, Int(round(bounds.extents.z * clampedScale.z * 100.0)))
                )
                let screenPoint = arView.project(entity.position(relativeTo: nil))
                parent.onScaleChanged?(percentage, dims, screenPoint)
            case .ended, .cancelled:
                parent.onScaleEnded?()
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
            
            // Performance: Smooth 60FPS throttling for real-time dragging
            let now = CACurrentMediaTime()
            guard now - lastPanRaycastTime >= 0.016 || recognizer.state == .ended else { return }
            lastPanRaycastTime = now
            
            let location = recognizer.location(in: arView)
            guard let worldTransform = ARSurfaceManager.performSurfaceRaycast(at: location, in: arView) else { return }
            
            if recognizer.state == .changed || recognizer.state == .ended {
                currentAnchor.setTransformMatrix(worldTransform, relativeTo: nil)
            }
        }
    }
}
