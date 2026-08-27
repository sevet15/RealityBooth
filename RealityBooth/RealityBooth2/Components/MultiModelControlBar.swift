//
//  MultiModelControlBar.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import SwiftUI

/// Bottom floating control platter for managing multiple 3D models in the AR scene
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
            // MARK: - Selected Model Inspector Platter
            if let selectedId = selectedModelId, let selected = models.first(where: { $0.id == selectedId }) {
                HStack(spacing: 12) {
                    Label(selected.name, systemImage: selected.systemIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Reset Pose Button (White Styling)
                    Button(action: onResetSelectedModel) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.22))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    
                    // Delete Button
                    Button(action: onDeleteSelectedModel) {
                        Image(systemName: "trash.fill")
                            .font(.caption.weight(.semibold))
                            .padding(8)
                            .background(Color.red.opacity(0.12))
                            .foregroundColor(.red)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    
                    // Deselect Button
                    Button(action: onDeselectModel) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .padding(8)
                            .background(Color.primary.opacity(0.08))
                            .foregroundColor(.secondary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 20)
                .frame(maxWidth: 540)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // MARK: - Bottom Main Controls Platter
            HStack(spacing: 12) {
                // Models Carousel (if models are placed)
                if !models.isEmpty {
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
                                    HStack(spacing: 6) {
                                        Image(systemName: item.systemIcon)
                                            .font(.caption)
                                        Text(item.name)
                                            .font(.caption.weight(isSelected ? .semibold : .medium))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        isSelected
                                            ? Color.blue
                                            : Color(UIColor.secondarySystemFill)
                                    )
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.15),
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                                .hoverEffect(.highlight)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Add / Cancel Action Button
                if pendingModel != nil {
                    Button(action: onCancelPending) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                            Text("Cancel")
                        }
                    }
                    .buttonStyle(CapsuleActionButtonStyle(backgroundColor: Color.gray))
                } else {
                    Button(action: onAddTap) {
                        HStack(spacing: 6) {
                            Image(systemName: isMaxReached ? "lock.fill" : "plus")
                            Text(models.isEmpty ? "Add Model" : "Add (\(models.count)/\(maxModels))")
                        }
                    }
                    .buttonStyle(
                        CapsuleActionButtonStyle(
                            backgroundColor: isMaxReached ? Color.gray : Color.blue,
                            isEnabled: !isMaxReached
                        )
                    )
                    .disabled(isMaxReached)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 6)
            .padding(.horizontal, 20)
            .frame(maxWidth: 640)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedModelId)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: models)
    }
}

#Preview {
    MultiModelControlBar(
        models: [
            ARModelItem(name: "Model 1", fileURL: URL(fileURLWithPath: "/"), systemIcon: "cube.fill"),
            ARModelItem(name: "Model 2", fileURL: URL(fileURLWithPath: "/"), systemIcon: "cube.transparent")
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
