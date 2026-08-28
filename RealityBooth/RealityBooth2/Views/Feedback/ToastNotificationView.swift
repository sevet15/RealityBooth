//
//  ToastNotificationView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Centered toast notification pill confirming photo saves
struct ToastNotificationView: View {
    var message: String = "Saved to Photos"
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.subheadline)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .liquidGlassCapsule(
            tint: Color(white: 0.3).opacity(0.55),
            strokeColors: [Color.white.opacity(0.5), Color.white.opacity(0.15)],
            shadowRadius: 14,
            shadowY: 6
        )
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}
