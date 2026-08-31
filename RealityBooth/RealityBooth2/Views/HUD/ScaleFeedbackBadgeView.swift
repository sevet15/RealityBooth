//
//  ScaleFeedbackBadgeView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 31/08/26.
//

import SwiftUI

/// Floating pill badge displaying real-time scale percentage (1:1 base) and live physical dimensions in centimeters
struct ScaleFeedbackBadgeView: View {
    let percentage: Int
    let dimensionsCm: SIMD3<Int>?
    let position: CGPoint?
    
    var body: some View {
        GeometryReader { geo in
            let targetX: CGFloat = {
                if let point = position {
                    return min(max(point.x, 100), geo.size.width - 100)
                } else {
                    return geo.size.width / 2.0
                }
            }()
            let targetY: CGFloat = {
                if let point = position {
                    return min(max(point.y - 110, 130), geo.size.height - 220)
                } else {
                    return geo.size.height * 0.38
                }
            }()
            
            HStack(spacing: 8) {
                Text("\(percentage)%")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                
                if let dims = dimensionsCm {
                    Text("•")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.45))
                    
                    Text("\(dims.x) × \(dims.y) × \(dims.z) cm")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.22))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
            .position(x: targetX, y: targetY)
        }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
        .zIndex(15)
        .allowsHitTesting(false)
    }
}
