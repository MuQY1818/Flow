import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)
            
            Divider()
            
            Text("Durations (minutes)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Grid(alignment: .leading, verticalSpacing: 12) {
                GridRow {
                    Text("Focus:")
                    TextField("25", value: $timerManager.focusDuration, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                GridRow {
                    Text("Short Break:")
                    TextField("5", value: $timerManager.shortBreakDuration, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                GridRow {
                    Text("Long Break:")
                    TextField("15", value: $timerManager.longBreakDuration, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }
            
            Spacer()
            
            HStack {
                Button("Quit App") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 250, height: 300)
    }
}
