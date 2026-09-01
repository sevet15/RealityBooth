//
//  TopHUDBarView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 28/08/26.
//

import SwiftUI

/// Top HUD bar displaying the scene model capacity badge and the Clear All action button with Apple HIG adaptive sizing
struct TopHUDBarView: View {
    @ObservedObject var viewModel: ARViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var isRegular: Bool { horizontalSizeClass == .regular }
    
    var body: some View {
        HStack {
            // Scene Capacity Badge Platter (Only visible after 3D models are added)
            if !viewModel.models.isEmpty {
                HStack(spacing: isRegular ? 10 : 8) {
                    Image(systemName: "cube.fill")
                        .foregroundColor(.white)
                        .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                    Text("\(viewModel.models.count) of \(ARConstants.maxSimultaneousModels) Models")
                        .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, isRegular ? 20 : 16)
                .padding(.vertical, isRegular ? 11 : 8)
                .liquidGlassCapsule(shadowRadius: 8, shadowY: 3)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
            
            Spacer()
            
            // Clear All Action Button (Visible when models exist and not in placement mode)
            if !viewModel.models.isEmpty && viewModel.pendingModel == nil {
                Button(action: {
                    viewModel.showClearAllConfirmation = true
                }) {
                    HStack(spacing: isRegular ? 8 : 6) {
                        Image(systemName: "trash.fill")
                        Text("Clear All")
                    }
                    .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, isRegular ? 20 : 16)
                    .padding(.vertical, isRegular ? 11 : 8)
                    .frame(minHeight: isRegular ? 44 : 38)
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
                .controlSize(isRegular ? .large : .regular)
                .hoverEffect(.highlight)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, isRegular ? 28 : 20)
        .frame(maxWidth: isRegular ? 680 : 540)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.models.isEmpty)
    }
}
