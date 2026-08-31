//
//  MultiModelControlBar.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import SwiftUI

/// Bottom floating control bar matching the liquid glass capsule design language
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
    
    var isMaxReached: Bool {
        models.count >= maxModels
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // MARK: - Selected Model Inspector Capsule (Only when a model is selected and no model is pending)
            if pendingModel == nil, let selectedId = selectedModelId, let selected = models.first(where: { $0.id == selectedId }) {
                HStack(spacing: 12) {
                    // Left: Model Icon & Name
                    HStack(spacing: 8) {
                        Image(systemName: selected.systemIcon)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                        Text(selected.name)
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, 6)
                    
                    Spacer()
                    
                    // Reset Button (Liquid Glass Pill)
                    Button(action: onResetSelectedModel) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption.weight(.bold))
                            Text("Reset")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .liquidGlassCapsule(
                            tint: Color.white.opacity(0.22),
                            strokeColors: [Color.white.opacity(0.6), Color.white.opacity(0.2)]
                        )
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    
                    // Delete Button (Solid Red Circle with White Trash Icon)
                    Button(action: onDeleteSelectedModel) {
                        Image(systemName: "trash.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(color: Color.red.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .liquidGlassCapsule(shadowRadius: 14, shadowY: 6)
                .padding(.horizontal, 20)
                .frame(maxWidth: 540)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // MARK: - Bottom Main Controls
            if pendingModel != nil {
                // Placing Model state: Clean centered liquid glass Cancel button
                Button(action: onCancelPending) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                        Text("Cancel")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .liquidGlassCapsule(shadowRadius: 8, shadowY: 3)
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
                .transition(.scale.combined(with: .opacity))
            } else if models.isEmpty {
                // Empty state: Clean standalone Add Model button
                Button(action: onAddTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.bold))
                        Text("Add Model")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
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
                .hoverEffect(.highlight)
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            } else {
                // Models Placed state: Liquid glass capsule containing models carousel with trailing blur fade and add button
                HStack(spacing: 8) {
                    // Scrollable Models with Right Edge Blur Fade Mask
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(models) { item in
                                let isSelected = item.id == selectedModelId
                                Button(action: {
                                    if isSelected {
                                        onDeselectModel()
                                    } else {
                                        onSelectModel(item.id)
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: item.systemIcon)
                                            .font(.caption.weight(.semibold))
                                        Text(item.name)
                                            .font(.caption.weight(.semibold))
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
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
                        HStack(spacing: 5) {
                            Image(systemName: isMaxReached ? "lock.fill" : "plus")
                                .font(.subheadline.weight(.bold))
                            Text("Add")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
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
                    .hoverEffect(.highlight)
                    .disabled(isMaxReached)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .liquidGlassCapsule(shadowRadius: 14, shadowY: 6)
                .padding(.horizontal, 20)
                .frame(maxWidth: 540)
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
