import SwiftUI
import Combine
import UserNotifications
import AppKit

class TimerManager: ObservableObject {
    enum TimerMode: String, CaseIterable {
        case focus = "Focus"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"
    }
    
    enum TimerState {
        case idle
        case running
        case paused
    }
    
    @Published var mode: TimerMode = .focus
    @Published var state: TimerState = .idle
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var progress: Double = 1.0
    
    // Durations in minutes
    @Published var focusDuration: Int = 25 {
        didSet { saveDurations() }
    }
    @Published var shortBreakDuration: Int = 5 {
        didSet { saveDurations() }
    }
    @Published var longBreakDuration: Int = 15 {
        didSet { saveDurations() }
    }
    
    private var timer: AnyCancellable?
    private var endDate: Date?
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var isRunning: Bool {
        state == .running
    }
    
    private let defaults = UserDefaults.standard
    private let historyKey = "TomatoSessions"
    private let durationKey = "TomatoDurations"
    
    @Published var sessions: [FocusSession] = []
    @Published var selectedTag: Tag = Tag.defaults.first!
    
    init() {
        requestNotificationPermission()
        loadHistory()
        loadDurations()
        generateMockData() // Add mock data for testing
    }
    
    private func generateMockData() {
        // Only generate if empty
        guard sessions.isEmpty else { return }
        
        let calendar = Calendar.current
        let today = Date()
        // Start of current week
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        var mockSessions: [FocusSession] = []
        
        // Generate sessions for each day of the week
        for dayOffset in 0...6 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }
            
            // Random number of sessions per day (0 to 5)
            let sessionsCount = Int.random(in: 0...5)
            
            for _ in 0..<sessionsCount {
                // Random time of day: Morning (9), Afternoon (14), Evening (20)
                let hour = [9, 14, 20].randomElement()! + Int.random(in: 0...2)
                let sessionDate = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date)!
                
                // Only add if it's in the past or today
                if sessionDate <= Date() {
                    let duration = TimeInterval(25 * 60) // 25 mins
                    let tag = Tag.defaults.randomElement()!
                    mockSessions.append(FocusSession(date: sessionDate, duration: duration, tag: tag.name))
                }
            }
        }
        
        sessions = mockSessions
        // Don't save mock data to persistence to avoid polluting real data permanently if not desired,
        // but for this request we'll set it to sessions.
    }
    
    private func loadHistory() {
        if let data = defaults.data(forKey: historyKey),
           let saved = try? JSONDecoder().decode([FocusSession].self, from: data) {
            sessions = saved
        }
    }
    
    private func loadDurations() {
        let savedFocus = defaults.integer(forKey: "focusDuration")
        if savedFocus > 0 { focusDuration = savedFocus }
        
        let savedShort = defaults.integer(forKey: "shortBreakDuration")
        if savedShort > 0 { shortBreakDuration = savedShort }
        
        let savedLong = defaults.integer(forKey: "longBreakDuration")
        if savedLong > 0 { longBreakDuration = savedLong }
    }
    
    private func saveDurations() {
        defaults.set(focusDuration, forKey: "focusDuration")
        defaults.set(shortBreakDuration, forKey: "shortBreakDuration")
        defaults.set(longBreakDuration, forKey: "longBreakDuration")
        
        // If idle, update current time remaining if the modified duration matches current mode
        if state == .idle {
            reset()
        }
    }
    
    func currentDuration() -> TimeInterval {
        switch mode {
        case .focus: return TimeInterval(focusDuration * 60)
        case .shortBreak: return TimeInterval(shortBreakDuration * 60)
        case .longBreak: return TimeInterval(longBreakDuration * 60)
        }
    }
    
    func start() {
        guard state != .running else { return }
        
        state = .running
        endDate = Date().addingTimeInterval(timeRemaining)
        
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func pause() {
        guard state == .running else { return }
        
        timer?.cancel()
        state = .paused
    }
    
    func reset() {
        timer?.cancel()
        state = .idle
        timeRemaining = currentDuration()
        progress = 1.0
    }
    
    func skip() {
        reset()
        // Cycle modes logic could go here, for now just reset
    }
    
    func setMode(_ newMode: TimerMode) {
        mode = newMode
        reset()
    }
    
    private func tick() {
        guard let endDate = endDate else { return }
        
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            completeTimer()
        } else {
            timeRemaining = remaining
            progress = remaining / currentDuration()
        }
    }
    
    private func saveSession() {
        // Only save Focus sessions
        guard mode == .focus else { return }
        
        let session = FocusSession(date: Date(), duration: currentDuration(), tag: selectedTag.name)
        sessions.append(session)
        
        if let encoded = try? JSONEncoder().encode(sessions) {
            defaults.set(encoded, forKey: historyKey)
        }
    }
    
    private func completeTimer() {
        saveSession()
        reset()
        sendNotification()
        playSound()
        // Auto-switch mode logic could go here
    }
    
    private func playSound() {
        // Use a system sound. "Glass" is a standard sound.
        if let sound = NSSound(named: "Glass") {
            sound.volume = 1.0
            sound.play()
        }
    }
    
    private func requestNotificationPermission() {
        // UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        print("Notifications disabled in CLI mode")
    }
    
    private func sendNotification() {
        /*
        let content = UNMutableNotificationContent()
        content.title = "Timer Finished"
        content.body = "\(mode.rawValue) session is complete."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        */
        print("Timer Finished: \(mode.rawValue)")
    }
}
