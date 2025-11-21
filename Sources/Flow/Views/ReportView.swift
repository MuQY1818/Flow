import SwiftUI
import Charts

struct ReportView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header: Week Selector
            WeekSelector(selectedDate: $selectedDate)
            
            // Summary Section
            VStack(spacing: 4) {
                Text("Today's Focus Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formattedTotalDuration)
                    .font(.system(size: 28, weight: .bold))
                
                Text(dateFormatted(selectedDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Cards
            HStack(spacing: 12) {
                SummaryCard(title: "Focus Count", value: "\(dailySessions.count)", unit: "times")
                SummaryCard(title: "Average", value: formattedAverageDuration, unit: "min")
            }
            
            // Chart
            DistributionChart(sessions: dailySessions)
                .frame(height: 80)
            
            // Tag Breakdown
            ScrollView {
                TagBreakdownList(sessions: dailySessions)
            }
            
            Spacer()
        }
        .padding()
    }
    
    var dailySessions: [FocusSession] {
        timerManager.sessions.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var formattedTotalDuration: String {
        let total = dailySessions.reduce(0) { $0 + $1.duration }
        let h = Int(total) / 3600
        let m = (Int(total) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
    
    var formattedAverageDuration: String {
        guard !dailySessions.isEmpty else { return "0" }
        let total = dailySessions.reduce(0) { $0 + $1.duration }
        let avg = Int(total) / dailySessions.count / 60
        return "\(avg)"
    }
    
    func dateFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: date)
    }
}

struct WeekSelector: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            ForEach(0..<7) { i in
                let date = Calendar.current.date(byAdding: .day, value: i - 3, to: Date())!
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                
                VStack {
                    Text(weekDay(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(dayNumber(date))
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(width: 30, height: 30)
                        .background(isSelected ? Color.blue : Color.clear)
                        .clipShape(Circle())
                }
                .onTapGesture { selectedDate = date }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    func weekDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
    
    func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline) {
                Text(value)
                    .font(.title2)
                    .bold()
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct DistributionChart: View {
    let sessions: [FocusSession]
    
    var body: some View {
        // Simplified 24h bar chart
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<24) { hour in
                let count = sessions.filter { Calendar.current.component(.hour, from: $0.date) == hour }.count
                Rectangle()
                    .fill(count > 0 ? Color.blue : Color.gray.opacity(0.1))
                    .frame(height: count > 0 ? CGFloat(count * 20) : 4)
            }
        }
    }
}

struct TagBreakdownList: View {
    let sessions: [FocusSession]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Tag.defaults) { tag in
                let tagSessions = sessions.filter { $0.tag == tag.name }
                if !tagSessions.isEmpty {
                    HStack {
                        Circle().fill(tag.color).frame(width: 8, height: 8)
                        Text(tag.name).font(.subheadline)
                        Spacer()
                        // Progress bar
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.gray.opacity(0.1))
                                Capsule().fill(tag.color).frame(width: g.size.width * (Double(tagSessions.count) / Double(sessions.count)))
                            }
                        }
                        .frame(height: 6)
                        .frame(width: 100)
                        
                        Text("\(tagSessions.count) times")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
