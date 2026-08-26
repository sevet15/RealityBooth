import SwiftUI

struct LoadingOverlayView: View {
    var body: some View {
        Text("Loading 3D Model...")
            .font(.headline)
            .padding()
            .background(Color.orange.opacity(0.75))
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

#Preview {
    LoadingOverlayView()
}
