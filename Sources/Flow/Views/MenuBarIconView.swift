import SwiftUI

struct MenuBarIconView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        if timerManager.useCompactMenuBar {
            CompactMenuBarIcon(timerManager: timerManager)
        } else {
            CapsuleMenuBarIcon(timerManager: timerManager)
        }
    }
}

// 紧凑模式：精美番茄图标 + 时间
struct CompactMenuBarIcon: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: 5) {
            // 精美番茄图标
            ZStack {
                // 番茄身体 - 使用更饱满的椭圆形状
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                modeColor.opacity(0.95),
                                modeColor,
                                modeColor.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 13, height: 12)
                    .offset(y: 1)
                
                // 高光
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: 6, height: 4)
                    .offset(x: -2, y: -1)
                
                // 番茄蒂 - 更自然的形状
                ZStack {
                    // 主茎
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.3, green: 0.6, blue: 0.3))
                        .frame(width: 2, height: 4)
                        .offset(y: -6)
                    
                    // 左叶
                    Ellipse()
                        .fill(Color(red: 0.35, green: 0.7, blue: 0.35))
                        .frame(width: 5, height: 3)
                        .rotationEffect(.degrees(-30))
                        .offset(x: -3, y: -5)
                    
                    // 右叶
                    Ellipse()
                        .fill(Color(red: 0.3, green: 0.65, blue: 0.3))
                        .frame(width: 5, height: 3)
                        .rotationEffect(.degrees(30))
                        .offset(x: 3, y: -5)
                }
                
                // 进度环 - 环绕番茄
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timerManager.progress)
            }
            .frame(width: 18, height: 20)
            
            // 时间显示
            Text(timerManager.formattedTime)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(height: 22)
        .padding(.horizontal, 2)
    }
    
    private var modeColor: Color {
        switch timerManager.mode {
        case .focus:
            return Color(red: 0.9, green: 0.25, blue: 0.2) // 鲜艳番茄红
        case .shortBreak:
            return Color(red: 0.2, green: 0.6, blue: 0.95) // 清爽蓝
        case .longBreak:
            return Color(red: 0.55, green: 0.35, blue: 0.85) // 优雅紫
        }
    }
}

// 胶囊模式（原有样式）
struct CapsuleMenuBarIcon: View {
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
