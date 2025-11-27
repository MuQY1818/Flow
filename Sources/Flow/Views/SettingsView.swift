import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @StateObject private var noiseManager = WhiteNoiseManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
            
            Divider()
            
            // 时长设置
            Text("Durations (minutes)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Grid(alignment: .leading, verticalSpacing: 10) {
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
            
            Divider()
            
            // 白噪音设置
            Text("White Noise")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Picker("", selection: $noiseManager.currentNoise) {
                    ForEach(NoiseType.allCases) { noise in
                        Label(noise.rawValue, systemImage: noise.icon)
                            .tag(noise)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                if noiseManager.currentNoise != .none {
                    Slider(value: $noiseManager.volume, in: 0...1)
                        .frame(width: 80)
                    
                    if noiseManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16)
                    } else {
                        Image(systemName: noiseManager.isPlaying ? "speaker.wave.2.fill" : "speaker.slash")
                            .foregroundColor(noiseManager.isPlaying ? .green : .gray)
                            .font(.caption)
                    }
                }
            }
            
            Divider()
            
            Toggle("Play Sound on Completion", isOn: $timerManager.isSoundEnabled)
            
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
        .frame(width: 300, height: 420)
    }
}
