import SwiftUI

/// 详细统计页面
struct DetailedStatsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Binding var isPresented: Bool
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var currentDate = Date()
    
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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(width: 28, height: 28)
                        .background(Color(white: 0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("专注统计")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                // 占位保持居中
                Color.clear.frame(width: 28, height: 28)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 时间段选择器
            HStack(spacing: 0) {
                ForEach(StatsPeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.title)
                            .font(.system(size: 13, weight: selectedPeriod == period ? .semibold : .regular))
                            .foregroundColor(selectedPeriod == period ? .white : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selectedPeriod == period ?
                                Color.green.opacity(0.8) : Color.clear
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color(white: 0.12))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            // 日期导航
            HStack {
                Button {
                    navigateDate(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(dateRangeText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    navigateDate(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
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
        .frame(width: 320, height: 500)
        .background(Color(red: 0.08, green: 0.08, blue: 0.1))
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
