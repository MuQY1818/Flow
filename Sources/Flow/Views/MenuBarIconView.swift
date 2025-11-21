import SwiftUI

struct MenuBarIconView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let progressWidth = max(height * 0.9, width * CGFloat(timerManager.progress))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            .blur(radius: 0.3)
                    )
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.35))
                            .blur(radius: 8)
                            .offset(y: 1)
                            .opacity(0.6)
                    )
                Capsule()
                    .fill(
                        LinearGradient(colors: [Color(red: 0.29, green: 0.96, blue: 0.68),
                                               Color(red: 0.17, green: 0.62, blue: 0.98)],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .frame(width: progressWidth, height: height * 0.92)
                    .padding(.vertical, height * 0.04)
                    .shadow(color: Color.green.opacity(0.35), radius: 8, x: 0, y: 5)
                    .animation(.easeInOut(duration: 0.45), value: timerManager.progress)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: progressWidth, height: height * 0.35)
                            .blur(radius: 4)
                            .offset(y: -height * 0.18)
                    )
                Text(timerManager.formattedTime)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: width, height: height, alignment: .center)
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
            }
            .clipShape(Capsule())
        }
        .frame(width: 70, height: 24)
        .padding(.vertical, 1)
    }
}
