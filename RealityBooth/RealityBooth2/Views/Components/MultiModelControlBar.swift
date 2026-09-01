//
//  MultiModelControlBar.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import SwiftUI

/// Bottom floating control bar matching the liquid glass capsule design language with Apple HIG adaptive sizing
struct MultiModelControlBar: View {
    let models: [ARModelItem]
    let selectedModelId: UUID?
    let pendingModel: ARModelItem?
    let maxModels: Int
    
    let onSelectModel: (UUID) -> Void
    let onDeselectModel: () -> Void
    let onDeleteSelectedModel: () -> Void
    let onResetSelectedModel: () -> Void
    let onAddTap: () -> Void
    let onCancelPending: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var isRegular: Bool { horizontalSizeClass == .regular }
    
    var containerMaxWidth: CGFloat {
        isRegular ? 680 : 540
    }
    
    var isMaxReached: Bool {
        models.count >= maxModels
    }
    
    var body: some View {
        VStack(spacing: isRegular ? 14 : 12) {
            // MARK: - Selected Model Inspector Capsule (Only when a model is selected and no model is pending)
            if pendingModel == nil, let selectedId = selectedModelId, let selected = models.first(where: { $0.id == selectedId }) {
                HStack(spacing: isRegular ? 16 : 12) {
                    // Left: Model Icon & Name
                    HStack(spacing: isRegular ? 10 : 8) {
                        Image(systemName: selected.systemIcon)
                            .font(isRegular ? .title3.weight(.semibold) : .body.weight(.semibold))
                            .foregroundColor(.white)
                        Text(selected.name)
                            .font(isRegular ? .body.weight(.bold) : .body.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, isRegular ? 8 : 6)
                    
                    Spacer()
                    
                    // Reset Button (Liquid Glass Pill with Apple HIG Large / Regular sizing)
                    Button(action: onResetSelectedModel) {
                        HStack(spacing: isRegular ? 6 : 5) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(isRegular ? .subheadline.weight(.bold) : .caption.weight(.bold))
                            Text("Reset")
                                .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, isRegular ? 18 : 14)
                        .padding(.vertical, isRegular ? 10 : 7)
                        .frame(minHeight: isRegular ? 44 : 36)
                        .liquidGlassCapsule(
                            tint: Color.white.opacity(0.22),
                            strokeColors: [Color.white.opacity(0.6), Color.white.opacity(0.2)]
                        )
                    }
                    .buttonStyle(.plain)
                    .controlSize(isRegular ? .large : .regular)
                    .hoverEffect(.highlight)
                    
                    // Delete Button (Solid Red Circle with White Trash Icon and HIG 44pt touch target)
                    Button(action: onDeleteSelectedModel) {
                        Image(systemName: "trash.fill")
                            .font(isRegular ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: isRegular ? 44 : 34, height: isRegular ? 44 : 34)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(color: Color.red.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .controlSize(isRegular ? .large : .regular)
                    .hoverEffect(.highlight)
                }
                .padding(.horizontal, isRegular ? 20 : 16)
                .padding(.vertical, isRegular ? 12 : 10)
                .liquidGlassCapsule(shadowRadius: 14, shadowY: 6)
                .padding(.horizontal, 20)
                .frame(maxWidth: containerMaxWidth)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // MARK: - Bottom Main Controls
            if pendingModel != nil {
                // Placing Model state: Clean centered liquid glass Cancel button
                Button(action: onCancelPending) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(isRegular ? .title3.weight(.bold) : .subheadline.weight(.bold))
                        Text("Cancel Placement")
                            .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isRegular ? 32 : 24)
                    .padding(.vertical, isRegular ? 16 : 14)
                    .frame(minHeight: isRegular ? 48 : 44)
                    .liquidGlassCapsule(
                        tint: Color.black.opacity(0.4),
                        strokeColors: [Color.white.opacity(0.5), Color.white.opacity(0.15)]
                    )
                }
                .buttonStyle(.plain)
                .controlSize(isRegular ? .large : .regular)
                .hoverEffect(.highlight)
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            } else if models.isEmpty {
                // Empty state: Clean prominent Add Model button
                Button(action: onAddTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(isRegular ? .title3.weight(.bold) : .subheadline.weight(.bold))
                        Text("Add Model")
                            .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, isRegular ? 32 : 24)
                    .padding(.vertical, isRegular ? 16 : 14)
                    .frame(minHeight: isRegular ? 48 : 44)
                    .background(Color(red: 0.0, green: 0.52, blue: 1.0))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.6), Color.white.opacity(0.15)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .controlSize(isRegular ? .large : .regular)
                .hoverEffect(.highlight)
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            } else {
                // Models Placed state: Liquid glass capsule containing models carousel with trailing blur fade and add button
                HStack(spacing: isRegular ? 10 : 8) {
                    // Scrollable Models with Right Edge Blur Fade Mask
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: isRegular ? 10 : 8) {
                            ForEach(models) { item in
                                let isSelected = item.id == selectedModelId
                                Button(action: {
                                    if isSelected {
                                        onDeselectModel()
                                    } else {
                                        onSelectModel(item.id)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: item.systemIcon)
                                            .font(isRegular ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
                                        Text(item.name)
                                            .font(isRegular ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, isRegular ? 16 : 12)
                                    .padding(.vertical, isRegular ? 11 : 8)
                                    .frame(minHeight: isRegular ? 44 : 36)
                                    .background(
                                        isSelected
                                            ? Color(red: 0.0, green: 0.52, blue: 1.0)
                                            : Color.white.opacity(0.2)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(isSelected ? 0.6 : 0.35),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(
                                        color: isSelected ? Color.blue.opacity(0.4) : Color.clear,
                                        radius: 4,
                                        x: 0,
                                        y: 2
                                    )
                                }
                                .buttonStyle(.plain)
                                .controlSize(isRegular ? .large : .regular)
                                .hoverEffect(.highlight)
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.leading, 2)
                        .padding(.trailing, 8)
                    }
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0.0),
                                .init(color: .black, location: 0.72),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Fixed Add Button on the right
                    Button(action: onAddTap) {
                        HStack(spacing: 6) {
                            Image(systemName: isMaxReached ? "lock.fill" : "plus")
                                .font(isRegular ? .body.weight(.bold) : .subheadline.weight(.bold))
                            Text("Add")
                                .font(isRegular ? .body.weight(.semibold) : .subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, isRegular ? 20 : 16)
                        .padding(.vertical, isRegular ? 12 : 10)
                        .frame(minHeight: isRegular ? 44 : 38)
                        .background(
                            isMaxReached
                                ? Color.gray.opacity(0.7)
                                : Color(red: 0.0, green: 0.52, blue: 1.0)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.15)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isMaxReached ? Color.clear : Color.blue.opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 3
                        )
                    }
                    .buttonStyle(.plain)
                    .controlSize(isRegular ? .large : .regular)
                    .hoverEffect(.highlight)
                    .disabled(isMaxReached)
                }
                .padding(.horizontal, isRegular ? 18 : 14)
                .padding(.vertical, isRegular ? 10 : 8)
                .liquidGlassCapsule(shadowRadius: 14, shadowY: 6)
                .padding(.horizontal, 20)
                .frame(maxWidth: containerMaxWidth)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedModelId)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: models)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: pendingModel)
    }
}

#Preview {
    MultiModelControlBar(
        models: [
            ARModelItem(name: "Model 1", fileURL: URL(fileURLWithPath: "/"), systemIcon: "cube.fill"),
            ARModelItem(name: "Model 2", fileURL: URL(fileURLWithPath: "/"), systemIcon: "cube.fill")
        ],
        selectedModelId: nil,
        pendingModel: nil,
        maxModels: 4,
        onSelectModel: { _ in },
        onDeselectModel: { },
        onDeleteSelectedModel: { },
        onResetSelectedModel: { },
        onAddTap: { },
        onCancelPending: { }
    )
}
