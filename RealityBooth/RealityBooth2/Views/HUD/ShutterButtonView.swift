//
//  ShutterButtonView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Floating liquid glass camera shutter button with Apple HIG adaptive touch targets
struct ShutterButtonView: View {
    @ObservedObject var viewModel: ARViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var isRegular: Bool { horizontalSizeClass == .regular }
    
    var buttonSize: CGFloat {
        isRegular ? 66 : 56
    }
    
    var iconSize: CGFloat {
        isRegular ? 26 : 22
    }
    
    var body: some View {
        Button(action: {
            viewModel.triggerScreenshot()
        }) {
            Image(systemName: "camera.fill")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: buttonSize, height: buttonSize)
                .liquidGlassCircle()
        }
        .buttonStyle(.plain)
        .controlSize(isRegular ? .large : .regular)
        .hoverEffect(.highlight)
        .transition(.scale.combined(with: .opacity))
    }
}
