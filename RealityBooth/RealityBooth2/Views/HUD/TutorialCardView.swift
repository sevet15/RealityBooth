//
//  TutorialCardView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Onboarding card displayed when the AR environment is empty
struct TutorialCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Real ini")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 2)
            
            tutorialRow(
                iconName: "plus.circle.fill",
                title: "Add 3D Models",
                description: "Place up to \(ARConstants.maxSimultaneousModels) models simultaneously into your physical space."
            )
            
            tutorialRow(
                iconName: "hand.tap.fill",
                title: "Detect & Place",
                description: "Point camera at a flat surface and tap to position objects."
            )
            
            tutorialRow(
                iconName: "hand.pinch.fill",
                title: "Transform & Move",
                description: "Drag to reposition, pinch to scale, and twist with two fingers to rotate."
            )
        }
        .padding(24)
        .liquidGlassCard(cornerRadius: 24)
        .padding(.horizontal, 24)
        .frame(maxWidth: 440)
    }
    
    private func tutorialRow(iconName: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
