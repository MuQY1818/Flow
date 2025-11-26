import SwiftUI
import AppKit

struct FloatingBallView: View {
    @ObservedObject var timerManager: TimerManager
    var onHide: (() -> Void)?
    
    @State private var isExpanded = false
    @State private var isPulsing = false
    @State private var flowPhase: CGFloat = 0
    @State private var showMenu = false
    
    private let ballSize: CGFloat = 60
    private let expandedWidth: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 0) {
            // 悬浮球主体
            ballView
            
            // 下拉菜单面板
            if showMenu {
                menuPanel
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .top))
                    ))
            }
        }
        .frame(width: 160, alignment: .center)  // 固定宽度防止跳动
        .onAppear {
            isPulsing = true
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                flowPhase = 1
            }
        }
        .onChange(of: timerManager.state) { newState in
            if newState == .running {
                isPulsing = true
            }
        }
    }
    
    // MARK: - 悬浮球视图
    private var ballView: some View {
        ZStack {
            // Glow effect layers
            if timerManager.state == .running {
                // Outer glow - pulsating
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                glowColor.opacity(0.4),
                                glowColor.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: ballSize / 2 - 5,
                            endRadius: ballSize / 2 + 20
                        )
                    )
                    .frame(width: ballSize + 40, height: ballSize + 40)
                    .blur(radius: 8)
                    .opacity(isPulsing ? 0.4 : 0.8)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
                
                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                glowColor.opacity(0.6),
                                glowColor.opacity(0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: ballSize / 2 - 10,
                            endRadius: ballSize / 2 + 5
                        )
                    )
                    .frame(width: ballSize + 10, height: ballSize + 10)
                    .blur(radius: 4)
            }
            
            // Main ball
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.15, green: 0.15, blue: 0.18),
                                Color(red: 0.08, green: 0.08, blue: 0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: ballSize, height: ballSize)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                
                // Border glow
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                glowColor.opacity(0.8),
                                glowColor.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: ballSize - 2, height: ballSize - 2)
                
                // Timer content
                VStack(spacing: 2) {
                    if isExpanded {
                        // Expanded mode: show full time
                        Text(timerManager.formattedTime)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    } else {
                        // Compact mode: show minutes only
                        Text(compactTime)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                // Progress ring with flowing effect
                ZStack {
                    // Base progress ring
                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(
                            glowColor.opacity(0.3),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: ballSize - 8, height: ballSize - 8)
                        .rotationEffect(.degrees(-90))
                    
                    // Flowing gradient overlay
                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: glowColor.opacity(0.2), location: 0),
                                    .init(color: glowColor, location: 0.3 + flowPhase * 0.4),
                                    .init(color: glowColor.opacity(0.8), location: 0.5 + flowPhase * 0.3),
                                    .init(color: glowColor.opacity(0.2), location: 1)
                                ]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: ballSize - 8, height: ballSize - 8)
                        .rotationEffect(.degrees(-90))
                }
                .animation(.linear(duration: 0.1), value: timerManager.progress)
            }
        }
        .frame(width: ballSize + 40, height: ballSize + 40)
        .contentShape(Circle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMenu.toggle()
            }
        }
    }
    
    // MARK: - 下拉菜单面板
    private var menuPanel: some View {
        VStack(spacing: 0) {
            // 连接悬浮球的小三角
            Triangle()
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                .frame(width: 14, height: 7)
            
            // 菜单内容
            VStack(spacing: 2) {
                // 暂停/继续
                MenuButton(
                    icon: timerManager.state == .running ? "pause.fill" : "play.fill",
                    title: timerManager.state == .running ? "暂停" : "继续",
                    color: glowColor
                ) {
                    if timerManager.state == .running {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                    closeMenu()
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // 跳过
                MenuButton(
                    icon: "forward.end.fill",
                    title: timerManager.mode == .focus ? "跳过专注" : "跳过休息",
                    color: .orange
                ) {
                    timerManager.skip()
                    closeMenu()
                }
                
                // 重置
                MenuButton(
                    icon: "arrow.counterclockwise",
                    title: "重置",
                    color: .gray
                ) {
                    timerManager.reset()
                    closeMenu()
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // 切换显示模式
                MenuButton(
                    icon: isExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical",
                    title: isExpanded ? "紧凑显示" : "展开显示",
                    color: .blue
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    closeMenu()
                }
                
                // 隐藏悬浮球
                MenuButton(
                    icon: "eye.slash.fill",
                    title: "隐藏",
                    color: .red.opacity(0.8)
                ) {
                    closeMenu()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onHide?()
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(width: 140)
            .background(Color(red: 0.12, green: 0.12, blue: 0.14))
            .cornerRadius(12)
        }
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        .offset(y: -8)
    }
    
    private func closeMenu() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            showMenu = false
        }
    }
    
    // Compact time display (minutes only)
    private var compactTime: String {
        let minutes = Int(timerManager.timeRemaining) / 60
        return "\(minutes)"
    }
    
    // Glow color based on timer mode
    private var glowColor: Color {
        switch timerManager.mode {
        case .focus:
            return Color(red: 0.2, green: 0.9, blue: 0.4) // Green
        case .shortBreak:
            return Color(red: 0.3, green: 0.7, blue: 1.0) // Blue
        case .longBreak:
            return Color(red: 0.8, green: 0.5, blue: 1.0) // Purple
        }
    }
    
    // Mode indicator color
    private var modeColor: Color {
        switch timerManager.mode {
        case .focus:
            return Color(red: 0.2, green: 0.9, blue: 0.4)
        case .shortBreak:
            return Color(red: 0.3, green: 0.7, blue: 1.0)
        case .longBreak:
            return Color(red: 0.8, green: 0.5, blue: 1.0)
        }
    }
}

// MARK: - 菜单按钮组件
struct MenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovered ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 小三角形状
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
