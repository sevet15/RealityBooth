//
//  LoadingOverlayView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI

/// Elegant glass platter loading overlay indicating asynchronous 3D model parsing and loading
struct LoadingOverlayView: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            
            Text("Loading 3D Model…")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    LoadingOverlayView()
}
