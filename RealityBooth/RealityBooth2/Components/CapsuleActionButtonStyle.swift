//
//  CapsuleActionButtonStyle.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI

/// A clean, modern capsule button style with no dark borders or harsh shadows
struct CapsuleActionButtonStyle: ButtonStyle {
    var backgroundColor: Color = Color.accentColor
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(
                backgroundColor
                    .opacity(isEnabled ? 1.0 : 0.6)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.75)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .hoverEffect(.automatic)
    }
}
