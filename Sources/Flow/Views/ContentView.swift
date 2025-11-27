import SwiftUI

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Namespace private var animation
    @State private var selectedTab = "Controls"
    @State private var showSettings = false
    @State private var hoveredTab: String? = nil
    @State private var quitHovered = false
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
                            let isSelected = selectedTab == tab
                            let isHovered = hoveredTab == tab
                            
                            Button {
                                // 使用弹簧动画让背景滑动更丝滑
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedTab = tab
                                }
                            } label: {
                                Text(tab)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(isSelected ? .white : (isHovered ? .white.opacity(0.9) : .gray))
                                    .frame(width: 80, height: 28)
                                    .background {
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(white: 0.2))
                                                .matchedGeometryEffect(id: "TabBackground", in: animation)
                                        } else if isHovered {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(white: 0.15))
                                        }
                                    }
                                    .scaleEffect(isHovered && !isSelected ? 1.05 : 1.0)
                                    // 绑定到具体的缩放条件，确保点击选中时的回缩动画也是轻快的
                                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isHovered && !isSelected)
                            }
                            .buttonStyle(.plain)
                            .onHover { h in hoveredTab = h ? tab : nil }
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
                            .foregroundColor(quitHovered ? .red : .gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(quitHovered ? Color.red.opacity(0.15) : Color.clear)
                            .cornerRadius(6)
                            .scaleEffect(quitHovered ? 1.05 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: quitHovered)
                    }
                    .buttonStyle(.plain)
                    .onHover { h in quitHovered = h }
                }
                .padding(20)
                .frame(height: 70) // Fixed height container to prevent jumps
                
                // Separator Line
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(white: 0.15))
                
                // Content Area
                ZStack(alignment: .top) {
                    if selectedTab == "Controls" {
                        TimerView(showSettings: $showSettings)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            .zIndex(1)
                    } else {
                        StatsView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .zIndex(0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped() // Prevent content from bleeding during transition
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
    @State private var tagHovered = false
    @State private var mainButtonHovered = false
    @State private var skipHovered = false
    @State private var settingsHovered = false
    @State private var isEditingGoal = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main Content Centered
            VStack(spacing: 0) {
                Spacer()
                
                // Goal Input (One Thing)
                if timerManager.mode == .focus {
                    ZStack {
                        if isEditingGoal || timerManager.currentGoal.isEmpty {
                            TextField("What's your goal?", text: $timerManager.currentGoal, onCommit: {
                                isEditingGoal = false
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 15, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .frame(width: 200)
                            .padding(.vertical, 4)
                            .background(Color.clear)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(isEditingGoal ? .white.opacity(0.5) : .clear)
                                    .offset(y: 10)
                            )
                        } else {
                            Text(timerManager.currentGoal)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            timerManager.state == .running ? Color.white.opacity(0.5) : Color.white.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: timerManager.state == .running ? Color.white.opacity(0.3) : Color.clear, radius: 5)
                                .onTapGesture {
                                    if timerManager.state != .running {
                                        isEditingGoal = true
                                    }
                                }
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: timerManager.state == .running)
                        }
                    }
                    .padding(.bottom, 16)
                }
                
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
                            .foregroundColor(tagHovered ? .white : .gray)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(tagHovered ? .white : .gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tagHovered ? Color(white: 0.2) : Color(white: 0.15))
                    .cornerRadius(12)
                    .scaleEffect(tagHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: tagHovered)
                }
                .menuStyle(.borderlessButton)
                .onHover { h in tagHovered = h }
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
                    .background(mainButtonHovered ? Color.white : Color(white: 0.85))
                    .cornerRadius(25)
                    .scaleEffect(mainButtonHovered ? 1.03 : 1.0)
                    .shadow(color: mainButtonHovered ? .white.opacity(0.3) : .clear, radius: 8)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: mainButtonHovered)
                }
                .buttonStyle(.plain)
                .onHover { h in mainButtonHovered = h }
                .padding(.horizontal, 30)
                
                // Skip button - 始终显示
                Button {
                    timerManager.skip()
                } label: {
                    Text(timerManager.mode == .focus ? "跳过专注" : "跳过休息")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(skipHovered ? .white : .gray)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                        .background(skipHovered ? Color(white: 0.25) : Color(white: 0.15))
                        .cornerRadius(14)
                        .scaleEffect(skipHovered ? 1.05 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: skipHovered)
                }
                .buttonStyle(.plain)
                .onHover { h in skipHovered = h }
                .padding(.top, 10)
                
                Spacer()
            
            }
            
            // Settings Button (Corner)
            Button {
                withAnimation { showSettings.toggle() }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(settingsHovered ? .white : .gray)
                    .frame(width: 36, height: 36)
                    .background(settingsHovered ? Color(white: 0.25) : Color(white: 0.15))
                    .clipShape(Circle())
                    .scaleEffect(settingsHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: settingsHovered)
            }
            .buttonStyle(.plain)
            .onHover { h in settingsHovered = h }
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
    @State private var leftArrowHovered = false
    @State private var rightArrowHovered = false
    @State private var showDetailedStats = false
    @State private var expandButtonHovered = false
    @State private var showShareSheet = false
    @State private var shareButtonHovered = false
    @State private var copySuccess = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main Content
            VStack(spacing: 10) {
                Spacer()
                
                // Date Range Header
            HStack {
                Button {
                    moveWeek(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(leftArrowHovered ? .white : .gray)
                        .frame(width: 28, height: 28)
                        .background(leftArrowHovered ? Color.white.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                        .scaleEffect(leftArrowHovered ? 1.1 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: leftArrowHovered)
                }
                .buttonStyle(.plain)
                .onHover { hovering in leftArrowHovered = hovering }
                
                Spacer()
                
                Text(dateRangeString)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    moveWeek(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(rightArrowHovered ? .white : .gray)
                        .frame(width: 28, height: 28)
                        .background(rightArrowHovered ? Color.white.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                        .scaleEffect(rightArrowHovered ? 1.1 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: rightArrowHovered)
                }
                .buttonStyle(.plain)
                .onHover { hovering in rightArrowHovered = hovering }
            }
            .padding(.horizontal, 30)
            .padding(.top, 5)
            
            // Total Focus
            VStack(spacing: 2) {
                Text(hoveredSummary?.title.uppercased() ?? "TOTAL FOCUS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .tracking(1)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: hoveredSummary?.id)
                
                FocusTimeDisplay(components: displayedDuration.focusTimeComponents())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: displayedDuration)
            }
            .padding(.vertical, 5)
            
            // Heatmap
            ContributionGraphView(weekStart: currentWeekStart, hoveredSummary: $hoveredSummary)
                .frame(height: 120)
            
                Spacer()
            }
            
            // Bottom Buttons
            HStack(spacing: 12) {
                // Share Button
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(shareButtonHovered ? .white : .gray)
                        .frame(width: 36, height: 36)
                        .background(shareButtonHovered ? Color.blue.opacity(0.3) : Color(white: 0.15))
                        .clipShape(Circle())
                        .scaleEffect(shareButtonHovered ? 1.1 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: shareButtonHovered)
                }
                .buttonStyle(.plain)
                .onHover { h in shareButtonHovered = h }
                
                // Detailed Stats Button
                Button {
                    showDetailedStats = true
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(expandButtonHovered ? .white : .gray)
                        .frame(width: 36, height: 36)
                        .background(expandButtonHovered ? Color.green.opacity(0.3) : Color(white: 0.15))
                        .clipShape(Circle())
                        .scaleEffect(expandButtonHovered ? 1.1 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: expandButtonHovered)
                }
                .buttonStyle(.plain)
                .onHover { h in expandButtonHovered = h }
            }
            .padding(20)
            
            // Share Overlay
            if showShareSheet {
                ZStack {
                    Color.black.opacity(0.85)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { showShareSheet = false }
                    
                    VStack(spacing: 20) {
                        ShareCardView(
                            dailyDuration: todayDuration,
                            sessionCount: todaySessions.count
                        )
                        .environmentObject(timerManager)
                        .scaleEffect(0.85)
                        .frame(width: 260 * 0.85, height: 350 * 0.85)
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                        
                        HStack(spacing: 16) {
                            Button {
                                copyToClipboard()
                            } label: {
                                HStack {
                                    Image(systemName: copySuccess ? "checkmark" : "doc.on.doc")
                                    Text(copySuccess ? "Copied" : "Copy")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                saveImage()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .zIndex(10)
            }
        }
        .onChange(of: currentWeekStart) { _ in
            hoveredSummary = nil
        }
        .onChange(of: showDetailedStats) { newValue in
            if newValue {
                openDetailedStatsWindow()
                showDetailedStats = false
            }
        }
    }
    
    var todaySessions: [FocusSession] {
        let calendar = Calendar.current
        return timerManager.sessions.filter { calendar.isDateInToday($0.date) }
    }
    
    var todayDuration: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.duration }
    }
    
    func copyToClipboard() {
        let cardView = ShareCardView(
            dailyDuration: todayDuration,
            sessionCount: todaySessions.count
        ).environmentObject(timerManager)
        
        if let image = cardView.snapshot() {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
            
            withAnimation { copySuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copySuccess = false
            }
        }
    }
    
    func saveImage() {
        let cardView = ShareCardView(
            dailyDuration: todayDuration,
            sessionCount: todaySessions.count
        ).environmentObject(timerManager)
        
        if let image = cardView.snapshot() {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.png]
            savePanel.canCreateDirectories = true
            savePanel.nameFieldStringValue = "Flow_Stats_\(Date().formatted(date: .numeric, time: .omitted)).png"
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    if let tiffData = image.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                        try? pngData.write(to: url)
                    }
                }
            }
        }
    }
    
    func moveWeek(by weeks: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: currentWeekStart) {
            withAnimation {
                currentWeekStart = newDate
            }
        }
    }
    
    /// 打开独立的详细统计窗口
    func openDetailedStatsWindow() {
        // 如果窗口已存在，直接显示
        if let existingWindow = StatsWindowController.shared.window {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 600),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "专注统计"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1)
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false  // 防止窗口提前释放
        window.center()
        
        let hostingView = NSHostingView(
            rootView: StandaloneStatsView()
                .environmentObject(timerManager)
        )
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        
        // 使用控制器管理窗口
        StatsWindowController.shared.setupWindow(window)
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
            .contentTransition(.numericText(countsDown: false))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
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
