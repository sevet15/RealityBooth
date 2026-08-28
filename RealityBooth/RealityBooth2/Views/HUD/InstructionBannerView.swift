//
//  InstructionBannerView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Banner displaying context-aware user guidance for placing or transforming models
struct InstructionBannerView: View {
    @ObservedObject var viewModel: ARViewModel
    
    var body: some View {
        if let pending = viewModel.pendingModel {
            // Placement Mode Guidance Banner
            HStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.subheadline.weight(.semibold))
                Text("Tap a flat surface to place \(pending.name)")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.0, green: 0.52, blue: 1.0))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)
            .frame(maxWidth: 540)
            .transition(.scale.combined(with: .opacity))
        } else if let selected = viewModel.selectedModel {
        
        }
    }
}
