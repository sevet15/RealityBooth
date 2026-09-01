//
//  ModelPickerSheet.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 27/08/26.
//

import SwiftUI

/// Non-floating bottom sheet for selecting sample 3D models or importing custom files
/// Engineered to anchor firmly to the bottom edge on both iPadOS and iOS
struct ModelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var isRegular: Bool { horizontalSizeClass == .regular }
    
    let currentModelCount: Int
    let maxModels: Int
    let onSelectBuiltIn: (BuiltInModel) -> Void
    let onOpenCustomFilePicker: () -> Void
    var onDismiss: (() -> Void)? = nil
    
    @State private var dragOffset: CGFloat = 0
    
    var isMaxCapacity: Bool {
        currentModelCount >= maxModels
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Native Drag Handle Indicator
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 38, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            // MARK: - Navigation Header with Title & Close Button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add 3D Model")
                        .font(isRegular ? .title2.weight(.bold) : .title3.weight(.bold))
                        .foregroundColor(.white)
                    Text("\(currentModelCount) of \(maxModels) slots used")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {
                    dismissSheet()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: isRegular ? 28 : 24))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            }
            .padding(.horizontal, isRegular ? 24 : 18)
            .padding(.top, 6)
            .padding(.bottom, 12)
            
            // MARK: - Content List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: isRegular ? 20 : 16) {
                    // Sample 3D Models Section
                    VStack(spacing: isRegular ? 14 : 12) {
                        ForEach(BuiltInModel.samples) { sample in
                            sampleModelCard(sample)
                        }
                    }
                    
                    // Custom Files Header
                    Text("Custom Files")
                        .font(isRegular ? .headline.weight(.semibold) : .subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, 4)
                        .padding(.horizontal, 4)
                    
                    // Custom Import Card
                    customImportCard
                }
                .padding(.horizontal, isRegular ? 24 : 18)
                .padding(.bottom, 34)
            }
        }
        .background(Color(red: 0.14, green: 0.14, blue: 0.16))
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 || value.velocity.height > 300 {
                        dismissSheet()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
    
    private func dismissSheet() {
        if let customDismiss = onDismiss {
            customDismiss()
        } else {
            dismiss()
        }
    }
    
    // MARK: - Subviews
    
    private func sampleModelCard(_ sample: BuiltInModel) -> some View {
        Button(action: {
            guard !isMaxCapacity else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            onSelectBuiltIn(sample)
            dismissSheet()
        }) {
            HStack(spacing: isRegular ? 18 : 16) {
                // Squircle Icon Badge with White Border
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(white: 0.22))
                        .frame(width: isRegular ? 56 : 50, height: isRegular ? 56 : 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2)
                        )
                    
                    Image(systemName: "cube.fill")
                        .font(isRegular ? .title2 : .title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(sample.name)
                        .font(isRegular ? .body.weight(.bold) : .body.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Sample 3D Asset • USDZ")
                        .font(isRegular ? .subheadline : .caption)
                        .foregroundColor(Color(white: 0.65))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 4)
                
                Image(systemName: isMaxCapacity ? "lock.fill" : "plus.circle.fill")
                    .font(.system(size: isRegular ? 28 : 26))
                    .foregroundColor(isMaxCapacity ? Color(white: 0.35) : Color(red: 0.0, green: 0.48, blue: 1.0))
            }
            .padding(.horizontal, isRegular ? 18 : 16)
            .padding(.vertical, isRegular ? 14 : 12)
            .frame(minHeight: isRegular ? 76 : 68)
            .background(Color(red: 0.21, green: 0.21, blue: 0.23))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isMaxCapacity ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .controlSize(isRegular ? .large : .regular)
        .disabled(isMaxCapacity)
    }
    
    private var customImportCard: some View {
        Button(action: {
            guard !isMaxCapacity else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            dismissSheet()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onOpenCustomFilePicker()
            }
        }) {
            HStack(spacing: isRegular ? 18 : 16) {
                // Squircle Icon Badge with White Border
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(white: 0.22))
                        .frame(width: isRegular ? 56 : 50, height: isRegular ? 56 : 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2)
                        )
                    
                    Image(systemName: "folder.badge.plus")
                        .font(isRegular ? .title2 : .title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Import from Files")
                        .font(isRegular ? .body.weight(.bold) : .body.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Text("Supports .usdz, .usdc, and .reality files")
                        .font(isRegular ? .subheadline : .caption)
                        .foregroundColor(Color(white: 0.65))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(isRegular ? .body.weight(.bold) : .body.weight(.semibold))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.horizontal, isRegular ? 18 : 16)
            .padding(.vertical, isRegular ? 14 : 12)
            .frame(minHeight: isRegular ? 76 : 68)
            .background(Color(red: 0.21, green: 0.21, blue: 0.23))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isMaxCapacity ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .controlSize(isRegular ? .large : .regular)
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
