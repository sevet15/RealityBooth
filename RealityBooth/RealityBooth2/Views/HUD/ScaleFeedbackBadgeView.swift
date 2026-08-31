//
//  ScaleFeedbackBadgeView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 31/08/26.
//

import SwiftUI

/// Floating pill badge displaying real-time scale percentage (1:1 base) and live physical dimensions (Width, Length, Height) in centimeters
struct ScaleFeedbackBadgeView: View {
    let percentage: Int
    let dimensionsCm: SIMD3<Int>?
    let position: CGPoint?
    
    var body: some View {
        GeometryReader { geo in
            let targetX: CGFloat = {
                if let point = position {
                    return min(max(point.x, 110), geo.size.width - 110)
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
                // Scale Percentage
                Text("\(percentage)%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .monospacedDigit()
                
                // Physical Dimensions with Apple HIG Initial Identifiers (Width × Length × Height in cm)
                if let dims = dimensionsCm {
                    Text("•")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.45))
                    
                    HStack(spacing: 6) {
                        // Width (X)
                        HStack(spacing: 2) {
                            Text("W:")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color.gray)
                            Text("\(dims.x)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.16))
                                .monospacedDigit()
                        }
                        
                        Text("×")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.gray.opacity(0.5))
                        
                        // Length (Z)
                        HStack(spacing: 2) {
                            Text("L:")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color.gray)
                            Text("\(dims.z)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.16))
                                .monospacedDigit()
                        }
                        
                        Text("×")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.gray.opacity(0.5))
                        
                        // Height (Y)
                        HStack(spacing: 2) {
                            Text("H:")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color.gray)
                            Text("\(dims.y)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.16))
                                .monospacedDigit()
                            Text("cm")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color.gray)
                                .padding(.leading, 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
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
