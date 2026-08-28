//
//  TopHUDBarView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Top HUD bar displaying the scene model capacity badge and the Clear All action button
struct TopHUDBarView: View {
    @ObservedObject var viewModel: ARViewModel
    
    var body: some View {
        HStack {
            // Scene Capacity Badge Platter
            HStack(spacing: 8) {
                Image(systemName: "cube.fill")
                    .foregroundColor(.white)
                    .font(.subheadline.weight(.semibold))
                Text("\(viewModel.models.count) of \(ARConstants.maxSimultaneousModels) Models")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .liquidGlassCapsule(shadowRadius: 8, shadowY: 3)
            
            Spacer()
            
            // Clear All Action Button (Visible when models exist and not placing)
            if !viewModel.models.isEmpty && viewModel.pendingModel == nil {
                Button(action: {
                    viewModel.showClearAllConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("Clear All")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.red.opacity(0.35), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: 540)
    }
}
