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

        // 6. Soft White Studio Lighting Rig (Key, Fill, and Overhead Directional Lights)
        let lightingAnchor = AnchorEntity(world: .zero)
        
        let keyLight = DirectionalLight()
        keyLight.light.color = .white
        keyLight.light.intensity = ARConstants.keyLightIntensity
        keyLight.light.isRealWorldProxy = true
        keyLight.look(at: [0, 0, 0], from: ARConstants.keyLightPosition, relativeTo: nil)
        lightingAnchor.addChild(keyLight)
        
        let fillLight = DirectionalLight()
        fillLight.light.color = UIColor(white: 0.98, alpha: 1.0)
        fillLight.light.intensity = ARConstants.fillLightIntensity
        fillLight.light.isRealWorldProxy = true
        fillLight.look(at: [0, 0, 0], from: ARConstants.fillLightPosition, relativeTo: nil)
        lightingAnchor.addChild(fillLight)
        
        let topLight = DirectionalLight()
        topLight.light.color = .white
        topLight.light.intensity = ARConstants.topLightIntensity
        topLight.light.isRealWorldProxy = true
        topLight.look(at: [0, 0, 0], from: ARConstants.topLightPosition, relativeTo: nil)
        lightingAnchor.addChild(topLight)
        
        arView.scene.addAnchor(lightingAnchor)

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
        
        // 0. Optimized 3D Selection Highlight (Only updates when selection ID changes)
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
        
        // 3. Handle Reset Transform Trigger (Non-blocking instantaneous transform reset)
        if resetTrigger {
            context.coordinator.resetModelTransform(for: selectedModelId)
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
        var baseDimensions: [UUID: SIMD3<Float>] = [:]
        
        // Cached indicator selection state to prevent heavy redundant mesh allocations
        var currentSelectedIndicatorId: UUID?
        
        // Loading state
        var currentLoadingId: UUID?
        var pendingEntity: Entity?
        private var loadTask: Task<Void, Never>?
        private var isCapturingSnapshot = false
        private var lastPanRaycastTime: TimeInterval = 0
        
        // Gesture transforms tracking
        var initialScale: SIMD3<Float> = ARConstants.defaultScale
        var initialOrientation: simd_quatf = ARConstants.defaultOrientation

        init(parent: ARViewContainer) {
            self.parent = parent
        }

        func updateSelectionIndicator(for selectedId: UUID?) {
            // Check if selection indicator is already current
            if selectedId == currentSelectedIndicatorId {
                if let id = selectedId, let entity = loadedEntities[id], entity.findEntity(named: ARSelectionIndicator.indicatorName) != nil {
                    return
                }
            }
            
            currentSelectedIndicatorId = selectedId
            
            // 1. Remove previous selection ring from all entities
            for (_, entity) in loadedEntities {
                if let existing = entity.findEntity(named: ARSelectionIndicator.indicatorName) {
                    existing.removeFromParent()
                }
            }
            
            // 2. Attach 3D outline selection ring centered at the bottom base of the selected model
            guard let selectedId = selectedId, let selectedEntity = loadedEntities[selectedId] else { return }
            let baseExtents = baseDimensions[selectedId]
            guard let ringEntity = ARSelectionIndicator.createIndicatorEntity(for: selectedEntity, baseExtents: baseExtents) else { return }
            selectedEntity.addChild(ringEntity)
        }

        func resetModelTransform(for selectedId: UUID?) {
            guard let selectedId = selectedId, let entity = loadedEntities[selectedId] else { return }
            
            // 1. Direct instantaneous transform reset on RealityKit entity
            entity.scale = ARConstants.defaultScale
            entity.orientation = ARConstants.defaultOrientation
            initialScale = ARConstants.defaultScale
            initialOrientation = ARConstants.defaultOrientation
            
            // 2. Read base dimensions
            if let baseExtents = baseDimensions[selectedId] {
                let dims = SIMD3<Int>(
                    max(1, Int(round(baseExtents.x * 100.0))),
                    max(1, Int(round(baseExtents.y * 100.0))),
                    max(1, Int(round(baseExtents.z * 100.0)))
                )
                let screenPoint: CGPoint?
                if let arView = arView,
                   let rawPoint = arView.project(entity.position(relativeTo: nil)),
                   rawPoint.x.isFinite, rawPoint.y.isFinite {
                    screenPoint = rawPoint
                } else {
                    screenPoint = nil
                }
                
                // 3. Dispatch feedback asynchronously on main queue so updateUIView completes cleanly
                DispatchQueue.main.async { [weak self] in
                    self?.parent.onScaleChanged?(100, dims, screenPoint)
                    self?.parent.onScaleEnded?()
                }
            }
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
                    
                    // 2. Add loaded model directly to container first to calculate true compounded orientation & bounds in parent space
                    container.addChild(loadedModel)
                    
                    // 3. Measure bounds in container coordinate space (where parent orientation is standard Y-up)
                    let boundsInContainer = container.visualBounds(relativeTo: container)
                    let extents = boundsInContainer.extents
                    
                    // Store 1:1 base physical extents (in meters)
                    self.baseDimensions[modelItem.id] = extents
                    
                    // 4. Precision Grounding: Offset model so its bottom vertex is at y = 0 and horizontally centered on (x=0, z=0)
                    loadedModel.position.x -= boundsInContainer.center.x
                    loadedModel.position.y -= boundsInContainer.min.y
                    loadedModel.position.z -= boundsInContainer.center.z
                    
                    // 5. Generate root box collision component matching exact 1:1 model bounds for instant hit testing
                    let boxWidth = max(0.05, extents.x)
                    let boxHeight = max(0.05, extents.y)
                    let boxDepth = max(0.05, extents.z)
                    let boxSize = SIMD3<Float>(boxWidth, boxHeight, boxDepth)
                    let boxCenter = SIMD3<Float>(0, boxHeight / 2.0, 0)
                    
                    container.components[CollisionComponent.self] = CollisionComponent(
                        shapes: [ShapeResource.generateBox(size: boxSize).offsetBy(translation: boxCenter)],
                        mode: .trigger,
                        filter: .default
                    )
                    
                    // 6. Add local soft white overhead point light for vibrant, bright model illumination
                    let modelLight = PointLight()
                    modelLight.name = "SoftWhiteModelLight"
                    modelLight.light.color = .white
                    modelLight.light.intensity = ARConstants.modelPointLightIntensity
                    modelLight.light.attenuationRadius = max(6.0, max(extents.x, max(extents.y, extents.z)) * 3.5)
                    modelLight.position = SIMD3<Float>(0, extents.y + 0.6, 0.2)
                    container.addChild(modelLight)
                    
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
            if currentSelectedIndicatorId == id {
                currentSelectedIndicatorId = nil
            }
            baseDimensions.removeValue(forKey: id)
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
            
            let baseExtents = baseDimensions[selectedId] ?? {
                let bounds = entity.visualBounds(relativeTo: entity)
                return bounds.extents
            }()

            switch recognizer.state {
            case .began:
                initialScale = entity.scale
                let currentScale = entity.scale.x
                let percentage = Int(round(currentScale * 100.0))
                let dims = SIMD3<Int>(
                    max(1, Int(round(baseExtents.x * currentScale * 100.0))),
                    max(1, Int(round(baseExtents.y * currentScale * 100.0))),
                    max(1, Int(round(baseExtents.z * currentScale * 100.0)))
                )
                let screenPoint: CGPoint?
                if let rawPoint = arView.project(entity.position(relativeTo: nil)),
                   rawPoint.x.isFinite, rawPoint.y.isFinite {
                    screenPoint = rawPoint
                } else {
                    screenPoint = nil
                }
                parent.onScaleChanged?(percentage, dims, screenPoint)
                
            case .changed:
                let scaleMultiplier = Float(recognizer.scale)
                let newScaleVal = initialScale.x * scaleMultiplier
                let clampedScale = max(ARConstants.minScale, min(ARConstants.maxScale, newScaleVal))
                
                entity.scale = SIMD3<Float>(repeating: clampedScale)
                
                let percentage = Int(round(clampedScale * 100.0))
                let dims = SIMD3<Int>(
                    max(1, Int(round(baseExtents.x * clampedScale * 100.0))),
                    max(1, Int(round(baseExtents.y * clampedScale * 100.0))),
                    max(1, Int(round(baseExtents.z * clampedScale * 100.0)))
                )
                let screenPoint: CGPoint?
                if let rawPoint = arView.project(entity.position(relativeTo: nil)),
                   rawPoint.x.isFinite, rawPoint.y.isFinite {
                    screenPoint = rawPoint
                } else {
                    screenPoint = nil
                }
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
