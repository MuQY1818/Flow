import SwiftUI

struct ContributionGraphView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    // The start date of the week to display
    var weekStart: Date
    @Binding var hoveredSummary: CellStat?
    
    let rows = 3 // Morning, Afternoon, Evening
    let columns = 7 // Days in a week
    let spacing: CGFloat = 4
    
    @State private var hoveredIndex: (col: Int, row: Int)? = nil
    @State private var tooltipFrame: CGRect? = nil
    @State private var gridCounts: [[Int]] = Array(repeating: Array(repeating: 0, count: 3), count: 7)
    @State private var gridDurations: [[TimeInterval]] = Array(repeating: Array(repeating: 0, count: 3), count: 7)
    private static let cellDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 8) {
                // Grid
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        VStack(spacing: spacing) {
                            // Morning (Top) -> Evening (Bottom)
                            ForEach(0..<rows, id: \.self) { row in
                                let cellDate = dateFor(col: col)
                                let timeOfDay = TimeOfDay(rawValue: row)!
                                // Use pre-calculated count & duration
                                let count = gridCounts[col][row]
                                let duration = gridDurations[col][row]
                                
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(colorFor(count: count))
                                        .onHover { isHovering in
                                            let frame = geo.frame(in: .named("GraphSpace"))
                                            if isHovering {
                                                tooltipFrame = frame
                                                hoveredIndex = (col, row)
                                                let stat = CellStat(date: cellDate, timeOfDay: timeOfDay, count: count, duration: duration)
                                                if stat.duration > 0 {
                                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                        hoveredSummary = stat
                                                    }
                                                } else if hoveredSummary != nil {
                                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                        hoveredSummary = nil
                                                    }
                                                }
                                            } else if hoveredIndex?.col == col && hoveredIndex?.row == row {
                                                tooltipFrame = nil
                                                hoveredIndex = nil
                                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                                    hoveredSummary = nil
                                                }
                                            }
                                        }
                                }
                                .frame(height: 26)
                            }
                            
                            // Day Label
                            Text(dayLabel(for: col))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        }
                    }
                }
                .coordinateSpace(name: "GraphSpace")
                .frame(maxWidth: .infinity)
                
                // Legend / Row Indicators
                Text("Morning · Afternoon · Evening")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal)
            
            // Tooltip Overlay
            if let hoveredIndex = hoveredIndex,
               let frame = tooltipFrame {
                let stat = statFor(col: hoveredIndex.col, row: hoveredIndex.row)
                TooltipView(stat: stat)
                    .position(x: frame.midX, y: frame.minY - 20)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.15), value: tooltipFrame)
            }
        }
        .onAppear { calculateGridData(start: weekStart) }
        .onChange(of: weekStart) { newValue in
            hoveredIndex = nil
            tooltipFrame = nil
            hoveredSummary = nil
            calculateGridData(start: newValue)
        }
        .onChange(of: timerManager.sessions.count) { _ in calculateGridData(start: weekStart) }
    }
    
    private func calculateGridData(start: Date) {
        // Initialize empty grid
        var newGridCounts = Array(repeating: Array(repeating: 0, count: 3), count: 7)
        var newGridDurations = Array(repeating: Array(repeating: 0.0, count: 3), count: 7)
        let calendar = Calendar.current
        
        // Filter sessions to only those in the current week view
        let end = calendar.date(byAdding: .day, value: 7, to: start)!
        
        let relevantSessions = timerManager.sessions.filter { $0.date >= start && $0.date < end }
        
        for session in relevantSessions {
            // Find column (day offset from weekStart)
            let dayComponent = calendar.dateComponents([.day], from: start, to: session.date)
            if let dayOffset = dayComponent.day, dayOffset >= 0 && dayOffset < 7 {
                // Find row (time of day)
                let row = TimeOfDay.from(date: session.date).rawValue
                newGridCounts[dayOffset][row] += 1
                newGridDurations[dayOffset][row] += session.duration
            }
        }
        
        self.gridCounts = newGridCounts
        self.gridDurations = newGridDurations
        if let hoveredIndex = hoveredIndex {
            let stat = statFor(col: hoveredIndex.col, row: hoveredIndex.row)
            hoveredSummary = stat
        }
    }
    
    enum TimeOfDay: Int {
        case morning = 0
        case afternoon = 1
        case evening = 2
        
        var label: String {
            switch self {
            case .morning: return "Morning"
            case .afternoon: return "Afternoon"
            case .evening: return "Evening"
            }
        }
        
        static func from(date: Date) -> TimeOfDay {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<12: return .morning
            case 12..<18: return .afternoon
            default: return .evening
            }
        }
    }
    
    func dateFor(col: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: col, to: weekStart) ?? weekStart
    }
    

    func countFor(date: Date, timeOfDay: TimeOfDay) -> Int {
        let calendar = Calendar.current
        return timerManager.sessions.filter { session in
            guard calendar.isDate(session.date, inSameDayAs: date) else { return false }
            return TimeOfDay.from(date: session.date) == timeOfDay
        }.count
    }

    private func statFor(col: Int, row: Int) -> CellStat {
        let cellDate = dateFor(col: col)
        let timeOfDay = TimeOfDay(rawValue: row) ?? .morning
        let count = gridCounts[col][row]
        let duration = gridDurations[col][row]
        return CellStat(date: cellDate, timeOfDay: timeOfDay, count: count, duration: duration)
    }
    
    func colorFor(count: Int) -> Color {
        if count == 0 { return Color(white: 0.2) }
        if count <= 1 { return Color(red: 0.1, green: 0.4, blue: 0.2) }
        if count <= 3 { return Color(red: 0.2, green: 0.6, blue: 0.3) }
        return Color(red: 0.3, green: 0.8, blue: 0.4)
    }
    
    func dayLabel(for col: Int) -> String {
        let calendar = Calendar.current
        let date = dateFor(col: col)
        let weekday = calendar.component(.weekday, from: date)
        return calendar.shortWeekdaySymbols[weekday - 1]
    }
}

struct TooltipView: View {
    let stat: ContributionGraphView.CellStat
    
    var body: some View {
        VStack(spacing: 3) {
            Text("\(stat.count) sessions")
                .font(.caption)
                .fontWeight(.bold)
            Text(stat.title)
                .font(.caption2)
            Text(stat.duration.focusTimeString())
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding(6)
        .background(Color.black.opacity(0.9))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .foregroundColor(.white)
        .shadow(radius: 4)
    }
}

extension ContributionGraphView {
    struct CellStat: Identifiable, Equatable {
        let date: Date
        let timeOfDay: TimeOfDay
        let count: Int
        let duration: TimeInterval
        
        var id: String {
            let dayStart = Calendar.current.startOfDay(for: date)
            return "\(dayStart.timeIntervalSince1970)-\(timeOfDay.rawValue)"
        }
        
        var title: String {
            let formatter = ContributionGraphView.cellDateFormatter
            return "\(formatter.string(from: date)) - \(timeOfDay.label)"
        }
    }
}

extension TimeInterval {
    func focusTimeString() -> String {
        let totalSeconds = max(0, Int(self.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
