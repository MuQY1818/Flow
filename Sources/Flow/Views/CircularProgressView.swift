import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var color: Color = .red
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.2)
                .foregroundColor(color)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear(duration: 0.1), value: progress)
        }
    }
}
