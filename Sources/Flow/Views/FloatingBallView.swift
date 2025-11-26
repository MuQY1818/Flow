import SwiftUI

struct FloatingBallView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var isExpanded = false
    @State private var isPulsing = false
    @State private var flowPhase: CGFloat = 0
    
    private let ballSize: CGFloat = 60
    private let expandedWidth: CGFloat = 120
    
    var body: some View {
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
                        
                        // Mode indicator dot
                        Circle()
                            .fill(modeColor)
                            .frame(width: 6, height: 6)
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
                    
                    // Bright tip at progress end
                    if timerManager.state == .running {
                        Circle()
                            .fill(glowColor)
                            .frame(width: 5, height: 5)
                            .shadow(color: glowColor, radius: 4)
                            .offset(y: -(ballSize - 8) / 2)
                            .rotationEffect(.degrees(-90 + 360 * timerManager.progress))
                    }
                }
                .animation(.linear(duration: 0.1), value: timerManager.progress)
            }
        }
        .frame(width: ballSize + 50, height: ballSize + 50)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
        .onAppear {
            isPulsing = true
            // Start flow animation
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
