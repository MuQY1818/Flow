import SwiftUI

struct MenuBarIconView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.1))
                
                // Progress Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(timerManager.selectedTag.color.opacity(0.8))
                    .frame(width: geometry.size.width * CGFloat(timerManager.progress))
                    .animation(.linear(duration: 1), value: timerManager.progress)
                
                // Time Text
                Text(timerManager.formattedTime)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(width: 60, height: 22) // Standard menu bar item size
        .padding(.vertical, 1)
    }
}
