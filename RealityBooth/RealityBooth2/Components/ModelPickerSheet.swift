//
//  ModelPickerSheet.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import SwiftUI

/// Modal sheet for selecting built-in sample models or importing custom USDZ / Reality files
struct ModelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let currentModelCount: Int
    let maxModels: Int
    let onSelectBuiltIn: (BuiltInModel) -> Void
    let onOpenCustomFilePicker: () -> Void
    
    var isMaxCapacity: Bool {
        currentModelCount >= maxModels
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Scene Capacity Indicator
                    HStack(spacing: 8) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .foregroundColor(.blue)
                        Text("\(currentModelCount) of \(maxModels) models in scene")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // MARK: - Sample Models Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sample 3D Models")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ForEach(BuiltInModel.samples) { sample in
                                Button(action: {
                                    onSelectBuiltIn(sample)
                                    dismiss()
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.12))
                                                .frame(width: 46, height: 46)
                                            Image(systemName: sample.systemIcon)
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(sample.name)
                                                .font(.body.weight(.semibold))
                                                .foregroundColor(.primary)
                                            Text(sample.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .hoverEffect(.highlight)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // MARK: - Custom Import Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom Files")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onOpenCustomFilePicker()
                            }
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.indigo.opacity(0.12))
                                        .frame(width: 46, height: 46)
                                    Image(systemName: "folder.badge.plus")
                                        .font(.title3)
                                        .foregroundColor(.indigo)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Import from Files")
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Text("Supports .usdz and .reality formats")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .hoverEffect(.highlight)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Add 3D Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ModelPickerSheet(
        currentModelCount: 1,
        maxModels: 4,
        onSelectBuiltIn: { _ in },
        onOpenCustomFilePicker: { }
    )
}
