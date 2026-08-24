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
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        
        // load 3d model
        guard let modelEntity = try? ModelEntity.load(named: "Enchant") else {
            print("Failed to load 3D model. Check that Enchant.usdz is in your project")
            return arView
        }
        
        // scale model
        modelEntity.scale = [0.1, 0.1, 0.1]
        
        // create the anchor
        let anchorEntity = AnchorEntity(plane: .horizontal)
        anchorEntity.addChild(modelEntity)
        arView.scene.addAnchor(anchorEntity)
        
        return arView
    }
    
    // Conformance requirement: keep this even if empty
    func updateUIView(_ uiView: ARView, context: Context) {
        // empty
    }
    func makedCoordinator() -> Coordinator {
        Coordinator()
    }
    class Coordinator {
        var selectedEntity: ModelEntity?
        var initialScale : SIMD3<Float> = [0.1, 0.1, 0.1]
        
        let minScale: Float = 0.01
        let maxScale: Float = 0.02
        
        //tap gesture
        
        @objc func handleTap(recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            
            let tapLocation = recognizer.location(in: arView)
            
            //raycast to find surface
            let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            guard let firstResult = result.first else {
                print("No surface was found - point camera at flat surface")
                return
                
            }
        }
    }
}
