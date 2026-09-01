//
//  InstructionBannerView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Banner displaying context-aware user guidance for placing models with iPad HIG adaptive width
struct InstructionBannerView: View {
    @ObservedObject var viewModel: ARViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var isRegular: Bool { horizontalSizeClass == .regular }
    
    var body: some View {
        if let pending = viewModel.pendingModel {
            // Placement Mode Guidance Banner (Orange Capsule)
            HStack(spacing: isRegular ? 10 : 8) {
                Image(systemName: "hand.tap.fill")
                    .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                Text("Tap a flat surface to place \(pending.name)")
                    .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, isRegular ? 24 : 18)
            .padding(.vertical, isRegular ? 14 : 12)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.98, green: 0.55, blue: 0.16))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.45), Color.white.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.orange.opacity(0.35), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)
            .frame(maxWidth: isRegular ? 680 : 540)
            .transition(.scale.combined(with: .opacity))
        }
    }
}
