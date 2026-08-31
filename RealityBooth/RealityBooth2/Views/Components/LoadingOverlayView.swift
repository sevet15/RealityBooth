//
//  LoadingOverlayView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI

/// Elegant glass platter loading overlay indicating asynchronous 3D operations
struct LoadingOverlayView: View {
    var message: String = "Loading 3D Model…"
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            
            Text(message)
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
    }
}

#Preview {
    LoadingOverlayView(message: "Clearing 3D Models…")
}
