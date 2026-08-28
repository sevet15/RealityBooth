//
//  ShutterButtonView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Floating liquid glass camera shutter button for capturing pure AR photos
struct ShutterButtonView: View {
    @ObservedObject var viewModel: ARViewModel
    
    var body: some View {
        Button(action: {
            viewModel.triggerScreenshot()
        }) {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .liquidGlassCircle()
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .transition(.scale.combined(with: .opacity))
    }
}
