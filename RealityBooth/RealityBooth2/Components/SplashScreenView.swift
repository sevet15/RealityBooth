//
//  SplashScreenView.swift
//  RealityBooth2
//
//  Created by Steven Valentino on 21/08/26.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var showSplash: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arkit")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.blue)
            
            Text("Real ini")
                .font(.system(size: 56, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + ARConstants.splashScreenDuration) {
                withAnimation(.easeOut(duration: ARConstants.splashScreenFadeDuration)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(showSplash: .constant(true))
}
