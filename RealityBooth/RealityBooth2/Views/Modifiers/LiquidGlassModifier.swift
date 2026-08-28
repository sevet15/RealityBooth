//
//  LiquidGlassModifier.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Design system modifier providing standardized Liquid Glass styling across all UI elements
struct LiquidGlassCapsuleModifier: ViewModifier {
    var tint: Color = Color(white: 0.35).opacity(0.55)
    var strokeColors: [Color] = [Color.white.opacity(0.45), Color.white.opacity(0.12)]
    var shadowRadius: CGFloat = 10
    var shadowY: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .background(
                Capsule()
                    .fill(tint)
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: strokeColors,
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: shadowRadius, x: 0, y: shadowY)
    }
}

struct LiquidGlassCircleModifier: ViewModifier {
    var tint: Color = Color(white: 0.35).opacity(0.55)
    var strokeColors: [Color] = [Color.white.opacity(0.65), Color.white.opacity(0.2)]
    var shadowRadius: CGFloat = 10
    var shadowY: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .fill(tint)
                    .background(.ultraThinMaterial, in: Circle())
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: strokeColors,
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: shadowRadius, x: 0, y: shadowY)
    }
}

struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24
    var tint: Color = Color(white: 0.35).opacity(0.55)
    var strokeColors: [Color] = [Color.white.opacity(0.4), Color.white.opacity(0.1)]
    var shadowRadius: CGFloat = 16
    var shadowY: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: strokeColors,
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: shadowRadius, x: 0, y: shadowY)
    }
}

extension View {
    func liquidGlassCapsule(
        tint: Color = Color(white: 0.35).opacity(0.55),
        strokeColors: [Color] = [Color.white.opacity(0.45), Color.white.opacity(0.12)],
        shadowRadius: CGFloat = 10,
        shadowY: CGFloat = 4
    ) -> some View {
        self.modifier(
            LiquidGlassCapsuleModifier(
                tint: tint,
                strokeColors: strokeColors,
                shadowRadius: shadowRadius,
                shadowY: shadowY
            )
        )
    }

    func liquidGlassCircle(
        tint: Color = Color(white: 0.35).opacity(0.55),
        strokeColors: [Color] = [Color.white.opacity(0.65), Color.white.opacity(0.2)],
        shadowRadius: CGFloat = 10,
        shadowY: CGFloat = 4
    ) -> some View {
        self.modifier(
            LiquidGlassCircleModifier(
                tint: tint,
                strokeColors: strokeColors,
                shadowRadius: shadowRadius,
                shadowY: shadowY
            )
        )
    }

    func liquidGlassCard(
        cornerRadius: CGFloat = 24,
        tint: Color = Color(white: 0.35).opacity(0.55),
        strokeColors: [Color] = [Color.white.opacity(0.4), Color.white.opacity(0.1)],
        shadowRadius: CGFloat = 16,
        shadowY: CGFloat = 8
    ) -> some View {
        self.modifier(
            LiquidGlassCardModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                strokeColors: strokeColors,
                shadowRadius: shadowRadius,
                shadowY: shadowY
            )
        )
    }
}
