import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Namespace private var animation
    @State private var selectedTab = "Controls"
    @State private var showSettings = false
    let tabs = ["Controls", "Stats"]
    
    var body: some View {
        ZStack {
            // Deep Dark Background
            Color(red: 0.05, green: 0.05, blue: 0.07).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.self) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(selectedTab == tab ? .white : .gray)
                                    .frame(width: 80, height: 28)
                                    .background {
                                        if selectedTab == tab {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(white: 0.2))
                                                .matchedGeometryEffect(id: "TabBackground", in: animation)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(Color(white: 0.12))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // Quit Button
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .frame(height: 70) // Fixed height container to prevent jumps
                
                // Separator Line
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(white: 0.15))
                
                // Content Area
                ZStack {
                    if selectedTab == "Controls" {
                        TimerView(showSettings: $showSettings)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            .zIndex(1)
                    } else {
                        StatsView()
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .zIndex(0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Settings Overlay
            if showSettings {
                Color.black.opacity(0.6)
                    .onTapGesture { withAnimation { showSettings = false } }
                    .zIndex(1)
                
                SettingsView()
                    .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                    .cornerRadius(16)
                    .shadow(radius: 20)
                    .overlay(
                        Button { withAnimation { showSettings = false } } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        .padding(10),
                        alignment: .topTrailing
                    )
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .frame(width: 320, height: 400)
        .preferredColorScheme(.dark)
    }
}

struct TimerView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Binding var showSettings: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main Content Centered
            VStack(spacing: 0) {
                Spacer()
                
                // Tag Selector
                Menu {
                    ForEach(Tag.defaults) { tag in
                        Button {
                            timerManager.selectedTag = tag
                        } label: {
                            HStack {
                                Circle().fill(tag.color).frame(width: 8, height: 8)
                                Text(tag.name)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(timerManager.selectedTag.color)
                            .frame(width: 6, height: 6)
                        
                        Text(timerManager.selectedTag.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(white: 0.15))
                    .cornerRadius(12)
                }
                .menuStyle(.borderlessButton)
                .padding(.bottom, 20)
                
                // Status Text with Flow Animation
                FlowText(text: timerManager.mode == .focus ? "Ready to Flow" : "Take a Break", 
                         isFlowing: timerManager.state == .running)
                    .padding(.bottom, 12)
                
                // Timer Display
                Text(timerManager.formattedTime)
                    .font(.system(size: 76, weight: .medium, design: .rounded)) // Large Rounded Font
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // Start/Pause Button
                Button {
                    if timerManager.state == .running {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                } label: {
                    HStack {
                        Image(systemName: timerManager.state == .running ? "pause.fill" : "play.fill")
                        Text(timerManager.state == .running ? "Pause \(timerManager.mode.rawValue)" : "Start \(timerManager.mode.rawValue)")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(white: 0.85))
                    .cornerRadius(25) // Fully rounded
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 30)
                
                if timerManager.mode != .focus {
                    Button {
                        timerManager.skip()
                    } label: {
                        Text("Skip \(timerManager.mode.rawValue)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(Color(white: 0.15))
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
                
                Spacer()
            
            }
            
            // Settings Button (Corner)
            Button {
                withAnimation { showSettings.toggle() }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 36, height: 36)
                    .background(Color(white: 0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(20)
        }
    }
}

struct StatsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var currentWeekStart: Date = {
        let calendar = Calendar.current
        let today = Date()
        // Find start of current week (Sunday)
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
    }()
    @State private var hoveredSummary: ContributionGraphView.CellStat? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            
            // Date Range Header
            HStack {
                Button {
                    moveWeek(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(dateRangeString)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    moveWeek(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 30)
            .foregroundColor(.gray)
            .padding(.top, 5)
            
            // Total Focus
            VStack(spacing: 2) {
                Text(hoveredSummary?.title.uppercased() ?? "TOTAL FOCUS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .tracking(1)
                    .animation(.easeInOut(duration: 0.25), value: hoveredSummary?.id)
                
                FocusTimeDisplay(components: displayedDuration.focusTimeComponents())
            }
            .padding(.vertical, 5)
            
            // Heatmap
            ContributionGraphView(weekStart: currentWeekStart, hoveredSummary: $hoveredSummary)
                .frame(height: 120)
            
            Spacer()
        }
        .padding(.bottom, 10)
        .onChange(of: currentWeekStart) { _ in
            hoveredSummary = nil
        }
    }
    
    func moveWeek(by weeks: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: currentWeekStart) {
            withAnimation {
                currentWeekStart = newDate
            }
        }
    }
    
    var dateRangeString: String {
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endOfWeek))"
    }
    
    var displayedDuration: TimeInterval {
        hoveredSummary?.duration ?? totalDuration
    }
    
    var totalDuration: TimeInterval {
        // Filter sessions for the displayed week
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
        // Make end of week encompass the whole day
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfWeek)!
        
        let sessionsInWeek = timerManager.sessions.filter { session in
            session.date >= currentWeekStart && session.date <= endOfDay
        }
        
        return sessionsInWeek.reduce(0) { $0 + $1.duration }
    }
}

struct FocusTimeDisplay: View {
    let components: FocusTimeComponents
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            AnimatedTimeNumber(value: components.hours)
            Text("h")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            AnimatedTimeNumber(value: components.minutes, padToTwoDigits: true)
            Text("m")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct AnimatedTimeNumber: View {
    let value: Int
    var padToTwoDigits: Bool = false
    
    var body: some View {
        Text(formattedValue)
            .font(.system(size: 52, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .monospacedDigit()
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: value)
    }
    
    private var formattedValue: String {
        padToTwoDigits ? String(format: "%02d", value) : "\(value)"
    }
}

struct FocusTimeComponents: Equatable {
    let hours: Int
    let minutes: Int
}

extension TimeInterval {
    func focusTimeComponents() -> FocusTimeComponents {
        let totalSeconds = max(0, Int(self.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return FocusTimeComponents(hours: hours, minutes: minutes)
    }
}

struct FlowText: View {
    let text: String
    let isFlowing: Bool
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.5)) // Matrix Green
            
            // Shimmer Overlay
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .opacity(0.5)
                .mask(
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white, .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width / 2)
                        .offset(x: phase * geo.size.width * 3 - geo.size.width)
                    }
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}
