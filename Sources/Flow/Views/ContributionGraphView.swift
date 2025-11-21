import SwiftUI

struct ContributionGraphView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    // The start date of the week to display
    var weekStart: Date
    
    let rows = 3 // Morning, Afternoon, Evening
    let columns = 7 // Days in a week
    let spacing: CGFloat = 4
    
    @State private var hoveredCell: (count: Int, date: Date, timeOfDay: TimeOfDay, frame: CGRect)? = nil
    @State private var gridCounts: [[Int]] = Array(repeating: Array(repeating: 0, count: 3), count: 7)
    
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
                                // Use pre-calculated count
                                let count = gridCounts[col][row]
                                
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(colorFor(count: count))
                                        .onHover { isHovering in
                                            if isHovering {
                                                hoveredCell = (count, cellDate, timeOfDay, geo.frame(in: .named("GraphSpace")))
                                            } else if hoveredCell?.frame == geo.frame(in: .named("GraphSpace")) {
                                                hoveredCell = nil
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
            if let hover = hoveredCell {
                TooltipView(count: hover.count, date: hover.date, timeOfDay: hover.timeOfDay)
                    .position(x: hover.frame.midX, y: hover.frame.minY - 20)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.1), value: hover.frame) // Smooth tooltip movement
            }
        }
        .onAppear { calculateGridData(start: weekStart) }
        .onChange(of: weekStart) { newValue in calculateGridData(start: newValue) }
        .onChange(of: timerManager.sessions.count) { _ in calculateGridData(start: weekStart) }
    }
    
    private func calculateGridData(start: Date) {
        // Initialize empty grid
        var newGrid = Array(repeating: Array(repeating: 0, count: 3), count: 7)
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
                newGrid[dayOffset][row] += 1
            }
        }
        
        self.gridCounts = newGrid
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
    let count: Int
    let date: Date
    let timeOfDay: ContributionGraphView.TimeOfDay
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count) sessions")
                .font(.caption)
                .fontWeight(.bold)
            Text("\(dateFormatted(date)) - \(timeOfDay.label)")
                .font(.caption2)
        }
        .padding(6)
        .background(Color.black.opacity(0.9))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .foregroundColor(.white)
        .shadow(radius: 4)
    }
    
    func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
