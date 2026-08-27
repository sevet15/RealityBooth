//
//  ModelPickerSheet.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import SwiftUI

struct ModelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let currentModelCount: Int
    let maxModels: Int
    let onSelectBuiltIn: (BuiltInModel) -> Void
    let onOpenCustomFilePicker: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Capacity indicator
                HStack {
                    Label("\(currentModelCount) of \(maxModels) models in scene", systemImage: "square.stack.3d.up")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Sample Models Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample 3D Models")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(BuiltInModel.samples, id: \.filename) { sample in
                        Button(action: {
                            onSelectBuiltIn(sample)
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: sample.systemIcon)
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sample.name)
                                        .font(.headline)
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
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Custom Upload Option
                Button(action: {
                    dismiss()
                    // Small delay to ensure sheet dismisses before file picker presents
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onOpenCustomFilePicker()
                    }
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title3)
                        Text("Import from Files (.usdz, .reality)")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
                }
                
                Spacer()
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
        currentModelCount: 2,
        maxModels: 4,
        onSelectBuiltIn: { _ in },
        onOpenCustomFilePicker: { }
    )
}
