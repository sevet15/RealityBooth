//
//  CapsuleActionButtonStyle.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI

/// A modern, HIG-compliant capsule button style featuring glassmorphism platter highlights and iPad hover effect
struct CapsuleActionButtonStyle: ButtonStyle {
    var backgroundColor: Color = Color.accentColor
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                backgroundColor
                    .opacity(isEnabled ? 1.0 : 0.6)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isEnabled ? backgroundColor.opacity(0.35) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .hoverEffect(.automatic)
    }
}
