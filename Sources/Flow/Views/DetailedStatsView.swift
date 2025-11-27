import SwiftUI
import AppKit

/// 详细统计页面
struct DetailedStatsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Binding var isPresented: Bool
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var currentDate = Date()
    @State private var closeHovered = false
    @State private var leftArrowHovered = false
    @State private var rightArrowHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部栏
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(closeHovered ? .white : .gray)
                        .frame(width: 26, height: 26)
                        .background(closeHovered ? Color.white.opacity(0.2) : Color(white: 0.15))
                        .clipShape(Circle())
                        .scaleEffect(closeHovered ? 1.1 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: closeHovered)
                }
                .buttonStyle(.plain)
                .onHover { h in closeHovered = h }
                
                Spacer()
                
                Text("专注统计")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Color.clear.frame(width: 26, height: 26)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // 时间段选择器（带悬停效果）
            HStack(spacing: 4) {
                ForEach(StatsPeriod.allCases, id: \.self) { period in
                    PeriodButton(
                        period: period,
                        isSelected: selectedPeriod == period
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedPeriod = period
                        }
                    }
                }
            }
            .padding(4)
            .background(Color(white: 0.1))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            
            // 日期导航
            HStack {
                Button {
                    navigateDate(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(leftArrowHovered ? .white : .gray)
                        .frame(width: 32, height: 32)
                        .background(leftArrowHovered ? Color.white.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .scaleEffect(leftArrowHovered ? 1.1 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: leftArrowHovered)
                }
                .buttonStyle(.plain)
                .onHover { h in leftArrowHovered = h }
                
                Spacer()
                
                Text(dateRangeText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    navigateDate(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(rightArrowHovered ? .white : .gray)
                        .frame(width: 32, height: 32)
                        .background(rightArrowHovered ? Color.white.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .scaleEffect(rightArrowHovered ? 1.1 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: rightArrowHovered)
                }
                .buttonStyle(.plain)
                .onHover { h in rightArrowHovered = h }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            
            // 统计卡片
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 总时长卡片
                    StatsCard {
                        VStack(spacing: 8) {
                            Text("总专注时长")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(totalHours)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("h")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("\(totalMinutes)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("m")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: totalDuration)
                        }
                    }
                    
                    // 番茄钟数量
                    HStack(spacing: 12) {
                        MiniStatsCard(
                            icon: "flame.fill",
                            color: .orange,
                            title: "番茄钟",
                            value: "\(sessionsCount)"
                        )
                        
                        MiniStatsCard(
                            icon: "clock.fill",
                            color: .blue,
                            title: "平均时长",
                            value: averageDuration
                        )
                    }
                    
                    // 柱状图
                    StatsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("专注趋势")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            BarChartView(data: chartData, period: selectedPeriod)
                                .frame(height: 120)
                        }
                    }
                    
                    // 最佳时段
                    if let bestTime = bestTimeOfDay {
                        StatsCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("最佳专注时段")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text(bestTime)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                Image(systemName: "star.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.yellow.opacity(0.8))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 400, height: 580)
        .background(Color(red: 0.06, green: 0.06, blue: 0.08))
        .cornerRadius(20)
    }
    
    // MARK: - 计算属性
    
    private var filteredSessions: [FocusSession] {
        let calendar = Calendar.current
        return timerManager.sessions.filter { session in
            switch selectedPeriod {
            case .day:
                return calendar.isDate(session.date, inSameDayAs: currentDate)
            case .week:
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                return session.date >= weekStart && session.date < weekEnd
            case .month:
                return calendar.isDate(session.date, equalTo: currentDate, toGranularity: .month)
            case .year:
                return calendar.isDate(session.date, equalTo: currentDate, toGranularity: .year)
            }
        }
    }
    
    private var totalDuration: TimeInterval {
        filteredSessions.reduce(0) { $0 + $1.duration }
    }
    
    private var totalHours: Int {
        Int(totalDuration) / 3600
    }
    
    private var totalMinutes: Int {
        (Int(totalDuration) % 3600) / 60
    }
    
    private var sessionsCount: Int {
        filteredSessions.count
    }
    
    private var averageDuration: String {
        guard sessionsCount > 0 else { return "0m" }
        let avg = totalDuration / Double(sessionsCount)
        let mins = Int(avg) / 60
        return "\(mins)m"
    }
    
    private var chartData: [Double] {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .day:
            // 24 小时
            var hourly = Array(repeating: 0.0, count: 24)
            for session in filteredSessions {
                let hour = calendar.component(.hour, from: session.date)
                hourly[hour] += session.duration / 60
            }
            return hourly
        case .week:
            // 7 天
            var daily = Array(repeating: 0.0, count: 7)
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
            for session in filteredSessions {
                let days = calendar.dateComponents([.day], from: weekStart, to: session.date).day ?? 0
                if days >= 0 && days < 7 {
                    daily[days] += session.duration / 60
                }
            }
            return daily
        case .month:
            // 4 周
            var weekly = Array(repeating: 0.0, count: 4)
            for session in filteredSessions {
                let week = calendar.component(.weekOfMonth, from: session.date) - 1
                if week >= 0 && week < 4 {
                    weekly[week] += session.duration / 60
                }
            }
            return weekly
        case .year:
            // 12 月
            var monthly = Array(repeating: 0.0, count: 12)
            for session in filteredSessions {
                let month = calendar.component(.month, from: session.date) - 1
                monthly[month] += session.duration / 60
            }
            return monthly
        }
    }
    
    private var bestTimeOfDay: String? {
        var timeCounts: [String: TimeInterval] = [
            "上午 (6-12)": 0,
            "下午 (12-18)": 0,
            "晚上 (18-24)": 0
        ]
        
        let calendar = Calendar.current
        for session in filteredSessions {
            let hour = calendar.component(.hour, from: session.date)
            if hour >= 6 && hour < 12 {
                timeCounts["上午 (6-12)"]! += session.duration
            } else if hour >= 12 && hour < 18 {
                timeCounts["下午 (12-18)"]! += session.duration
            } else if hour >= 18 {
                timeCounts["晚上 (18-24)"]! += session.duration
            }
        }
        
        return timeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .day:
            formatter.dateFormat = "M月d日 EEEE"
            return formatter.string(from: currentDate)
        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            formatter.dateFormat = "M/d"
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        case .month:
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: currentDate)
        case .year:
            formatter.dateFormat = "yyyy年"
            return formatter.string(from: currentDate)
        }
    }
    
    private func navigateDate(by value: Int) {
        let calendar = Calendar.current
        var component: Calendar.Component
        
        switch selectedPeriod {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        }
        
        if let newDate = calendar.date(byAdding: component, value: value, to: currentDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                currentDate = newDate
            }
        }
    }
}

// MARK: - 子组件

enum StatsPeriod: CaseIterable {
    case day, week, month, year
    
    var title: String {
        switch self {
        case .day: return "日"
        case .week: return "周"
        case .month: return "月"
        case .year: return "年"
        }
    }
}

/// 时间段按钮（带悬停效果）
struct PeriodButton: View {
    let period: StatsPeriod
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(period.title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : (isHovered ? .white.opacity(0.9) : .gray))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Color.green.opacity(0.85)
                        } else if isHovered {
                            Color.white.opacity(0.1)
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(8)
                .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

struct StatsCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.12))
            .cornerRadius(16)
    }
}

struct MiniStatsCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(white: 0.12))
        .cornerRadius(16)
    }
}

/// 玻璃拟态统计卡片
struct GlassStatsCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 10) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // 标题
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            // 数值
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

struct BarChartView: View {
    let data: [Double]
    let period: StatsPeriod
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: period == .day ? 2 : 8) {
                ForEach(0..<data.count, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: barHeight(for: data[index], maxHeight: geo.size.height - 20))
                        
                        if shouldShowLabel(index: index) {
                            Text(labelFor(index: index))
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
    
    private func barHeight(for value: Double, maxHeight: CGFloat) -> CGFloat {
        let maxValue = data.max() ?? 1
        guard maxValue > 0 else { return 4 }
        return max(4, CGFloat(value / maxValue) * maxHeight)
    }
    
    private func shouldShowLabel(index: Int) -> Bool {
        switch period {
        case .day: return index % 6 == 0
        case .week: return true
        case .month: return true
        case .year: return index % 2 == 0
        }
    }
    
    private func labelFor(index: Int) -> String {
        switch period {
        case .day: return "\(index)"
        case .week: return ["日", "一", "二", "三", "四", "五", "六"][index]
        case .month: return "W\(index + 1)"
        case .year: return "\(index + 1)"
        }
    }
}

// MARK: - 独立窗口版本

/// 窗口控制器（保持引用防止窗口被释放）
class StatsWindowController: NSObject, NSWindowDelegate {
    static let shared = StatsWindowController()
    var window: NSWindow?
    
    func windowWillClose(_ notification: Notification) {
        // 窗口关闭时清理引用
        window = nil
    }
    
    func setupWindow(_ window: NSWindow) {
        self.window = window
        window.delegate = self
    }
}

/// 独立窗口的统计视图
struct StandaloneStatsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var currentDate = Date()
    @State private var leftArrowHovered = false
    @State private var rightArrowHovered = false
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部标题区域
                VStack(spacing: 16) {
                    Text("专注统计")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    // 时间段选择器
                    HStack(spacing: 6) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            PeriodButton(
                                period: period,
                                isSelected: selectedPeriod == period
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedPeriod = period
                                }
                            }
                        }
                    }
                    .padding(5)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 12)
                
                // 日期导航
                HStack {
                    Button {
                        navigateDate(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(leftArrowHovered ? .white : .gray)
                            .frame(width: 36, height: 36)
                            .background(leftArrowHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .scaleEffect(leftArrowHovered ? 1.08 : 1.0)
                            .animation(.easeOut(duration: 0.15), value: leftArrowHovered)
                    }
                    .buttonStyle(.plain)
                    .onHover { h in leftArrowHovered = h }
                    
                    Spacer()
                    
                    Text(dateRangeText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    Button {
                        navigateDate(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(rightArrowHovered ? .white : .gray)
                            .frame(width: 36, height: 36)
                            .background(rightArrowHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .scaleEffect(rightArrowHovered ? 1.08 : 1.0)
                            .animation(.easeOut(duration: 0.15), value: rightArrowHovered)
                    }
                    .buttonStyle(.plain)
                    .onHover { h in rightArrowHovered = h }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
                // 统计内容
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 主要统计卡片 - 总时长（带渐变背景）
                        VStack(spacing: 6) {
                            Text("总专注时长")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(totalHours)")
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                Text("h")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(.trailing, 4)
                                Text("\(totalMinutes)")
                                    .font(.system(size: 64, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                Text("m")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: totalDuration)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.green.opacity(0.15),
                                            Color.blue.opacity(0.1),
                                            Color.purple.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        
                        // 双列统计卡片
                        HStack(spacing: 12) {
                            // 番茄钟数量
                            GlassStatsCard(
                                icon: "flame.fill",
                                iconColor: .orange,
                                title: "番茄钟",
                                value: "\(sessionsCount)",
                                unit: "个"
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            
                            // 平均时长
                            GlassStatsCard(
                                icon: "timer",
                                iconColor: .cyan,
                                title: "平均时长",
                                value: averageDuration,
                                unit: ""
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        }
                        
                        // 专注趋势图
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                                Text("专注趋势")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            BarChartView(data: chartData, period: selectedPeriod)
                                .frame(height: 130)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        
                        // 最佳时段
                        if let bestTime = bestTimeOfDay {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.yellow)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("最佳专注时段")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(bestTime)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.green, .cyan],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                
                                Spacer()
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 580)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }
    
    // MARK: - 计算属性
    
    private var filteredSessions: [FocusSession] {
        let calendar = Calendar.current
        return timerManager.sessions.filter { session in
            switch selectedPeriod {
            case .day:
                return calendar.isDate(session.date, inSameDayAs: currentDate)
            case .week:
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                return session.date >= weekStart && session.date < weekEnd
            case .month:
                return calendar.isDate(session.date, equalTo: currentDate, toGranularity: .month)
            case .year:
                return calendar.isDate(session.date, equalTo: currentDate, toGranularity: .year)
            }
        }
    }
    
    private var totalDuration: TimeInterval {
        filteredSessions.reduce(0) { $0 + $1.duration }
    }
    
    private var totalHours: Int { Int(totalDuration) / 3600 }
    private var totalMinutes: Int { (Int(totalDuration) % 3600) / 60 }
    private var sessionsCount: Int { filteredSessions.count }
    
    private var averageDuration: String {
        guard sessionsCount > 0 else { return "0m" }
        return "\(Int(totalDuration / Double(sessionsCount)) / 60)m"
    }
    
    private var chartData: [Double] {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            var hourly = Array(repeating: 0.0, count: 24)
            for session in filteredSessions {
                let hour = calendar.component(.hour, from: session.date)
                hourly[hour] += session.duration / 60
            }
            return hourly
        case .week:
            var daily = Array(repeating: 0.0, count: 7)
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
            for session in filteredSessions {
                let days = calendar.dateComponents([.day], from: weekStart, to: session.date).day ?? 0
                if days >= 0 && days < 7 { daily[days] += session.duration / 60 }
            }
            return daily
        case .month:
            var weekly = Array(repeating: 0.0, count: 4)
            for session in filteredSessions {
                let week = calendar.component(.weekOfMonth, from: session.date) - 1
                if week >= 0 && week < 4 { weekly[week] += session.duration / 60 }
            }
            return weekly
        case .year:
            var monthly = Array(repeating: 0.0, count: 12)
            for session in filteredSessions {
                let month = calendar.component(.month, from: session.date) - 1
                monthly[month] += session.duration / 60
            }
            return monthly
        }
    }
    
    private var bestTimeOfDay: String? {
        var timeCounts: [String: TimeInterval] = [
            "上午 (6-12)": 0, "下午 (12-18)": 0, "晚上 (18-24)": 0
        ]
        let calendar = Calendar.current
        for session in filteredSessions {
            let hour = calendar.component(.hour, from: session.date)
            if hour >= 6 && hour < 12 { timeCounts["上午 (6-12)"]! += session.duration }
            else if hour >= 12 && hour < 18 { timeCounts["下午 (12-18)"]! += session.duration }
            else if hour >= 18 { timeCounts["晚上 (18-24)"]! += session.duration }
        }
        return timeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        switch selectedPeriod {
        case .day:
            formatter.dateFormat = "M月d日 EEEE"
            return formatter.string(from: currentDate)
        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            formatter.dateFormat = "M/d"
            return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
        case .month:
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: currentDate)
        case .year:
            formatter.dateFormat = "yyyy年"
            return formatter.string(from: currentDate)
        }
    }
    
    private func navigateDate(by value: Int) {
        let calendar = Calendar.current
        let component: Calendar.Component = {
            switch selectedPeriod {
            case .day: return .day
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }()
        if let newDate = calendar.date(byAdding: component, value: value, to: currentDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                currentDate = newDate
            }
        }
    }
}
