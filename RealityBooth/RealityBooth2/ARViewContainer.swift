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
        return arView
    }

    // Fixed typo: 'updateUIView' (lowercase 'i')
    func updateUIView(_ uiView: ARView, context: Context) {
        // empty
    }
}

