//
//  ModelPickerSheet.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import SwiftUI

/// Modal sheet for selecting sample 3D models or importing custom files
/// Pixel-accurate recreation of reference layout with solid gray cards, white frame squircle icons, and native sheet presentation
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // MARK: - Title Header
                Text("Add 3D Model")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.top, 18)
                    .padding(.horizontal, 4)
                
                // MARK: - Sample 3D Models Section
                VStack(spacing: 12) {
                    ForEach(BuiltInModel.samples) { sample in
                        sampleModelCard(sample)
                    }
                }
                
                // MARK: - Custom Files Header
                Text("Custom Files")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 6)
                    .padding(.horizontal, 4)
                
                // MARK: - Custom Import Card
                customImportCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Color(red: 0.14, green: 0.14, blue: 0.16))
    }
    
    // MARK: - Subviews
    
    private func sampleModelCard(_ sample: BuiltInModel) -> some View {
        Button(action: {
            guard !isMaxCapacity else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            onSelectBuiltIn(sample)
            dismiss()
        }) {
            HStack(spacing: 16) {
                // Squircle Icon Badge with White Border
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(white: 0.22))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2)
                        )
                    
                    Image(systemName: "cube.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(sample.name)
                        .font(.body.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Sample 3D Asset • USDZ")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.65))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                Image(systemName: isMaxCapacity ? "lock.fill" : "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(isMaxCapacity ? Color(white: 0.35) : Color(red: 0.0, green: 0.48, blue: 1.0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 72)
            .background(Color(red: 0.21, green: 0.21, blue: 0.23))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isMaxCapacity ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isMaxCapacity)
    }
    
    private var customImportCard: some View {
        Button(action: {
            guard !isMaxCapacity else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onOpenCustomFilePicker()
            }
        }) {
            HStack(spacing: 16) {
                // Squircle Icon Badge with White Border
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(white: 0.22))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2)
                        )
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Import from Files")
                        .font(.body.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("Supports standard .usdz and .reality AR files")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.65))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 72)
            .background(Color(red: 0.21, green: 0.21, blue: 0.23))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isMaxCapacity ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isMaxCapacity)
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
