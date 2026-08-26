import SwiftUI

struct SplashScreenView: View {
    // This binding allows the splash screen to tell the main view to hide it
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(showSplash: .constant(true))
}
