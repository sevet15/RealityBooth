//
//  MultiModelControlBar.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import SwiftUI

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
            // Selected Model Actions Overlay (if a model is selected)
            if let selectedId = selectedModelId, let selected = models.first(where: { $0.id == selectedId }) {
                HStack(spacing: 14) {
                    Label(selected.name, systemImage: selected.systemIcon)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Reset Transform Button
                    Button(action: onResetSelectedModel) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    
                    // Delete Button
                    Button(action: onDeleteSelectedModel) {
                        Image(systemName: "trash.fill")
                            .font(.caption.bold())
                            .padding(8)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(Circle())
                    }
                    
                    // Deselect Button
                    Button(action: onDeselectModel) {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.secondary)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Models Carousel & Add Controls
            HStack(spacing: 12) {
                // Models List Scroll (if there are placed models)
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
                                            .font(.caption.weight(isSelected ? .bold : .medium))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.blue : Color(UIColor.systemBackground).opacity(0.85))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? Color.white.opacity(0.8) : Color.clear, lineWidth: 1.5)
                                    )
                                    .shadow(color: isSelected ? Color.blue.opacity(0.4) : Color.black.opacity(0.1), radius: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Add / Cancel Button
                if pendingModel != nil {
                    Button(action: onCancelPending) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel")
                        }
                    }
                    .buttonStyle(CapsuleActionButtonStyle(backgroundColor: Color.gray))
                } else {
                    Button(action: onAddTap) {
                        HStack(spacing: 8) {
                            Image(systemName: isMaxReached ? "lock.fill" : "plus")
                            Text(models.isEmpty ? "Add 3D Model" : "Add (\(models.count)/\(maxModels))")
                        }
                    }
                    .buttonStyle(CapsuleActionButtonStyle(backgroundColor: isMaxReached ? Color.gray : Color(red: 0.0, green: 0.55, blue: 1.0)))
                    .disabled(isMaxReached)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selectedModelId)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: models)
    }
}

#Preview {
    MultiModelControlBar(
        models: [
            ARModelItem(name: "Ferrari", fileURL: URL(fileURLWithPath: "/"), systemIcon: "car.fill"),
            ARModelItem(name: "Enchant", fileURL: URL(fileURLWithPath: "/"), systemIcon: "sparkles")
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
