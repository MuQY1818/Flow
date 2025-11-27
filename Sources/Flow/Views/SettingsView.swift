import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @StateObject private var noiseManager = WhiteNoiseManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("设置")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 时长设置
                    SettingsSection(title: "专注时长") {
                        SettingsRow(icon: "brain.head.profile", title: "专注", color: .green) {
                            DurationStepper(value: $timerManager.focusDuration, range: 1...120)
                        }
                        SettingsRow(icon: "cup.and.saucer", title: "短休息", color: .blue) {
                            DurationStepper(value: $timerManager.shortBreakDuration, range: 1...30)
                        }
                        SettingsRow(icon: "moon.stars", title: "长休息", color: .purple) {
                            DurationStepper(value: $timerManager.longBreakDuration, range: 1...60)
                        }
                    }
                    
                    // 声音设置
                    SettingsSection(title: "声音") {
                        SettingsRow(icon: "speaker.wave.2", title: "完成提示音", color: .orange) {
                            Toggle("", isOn: $timerManager.isSoundEnabled)
                                .toggleStyle(.switch)
                                .scaleEffect(0.8)
                        }
                        
                        SettingsRow(icon: "waveform", title: "白噪音", color: .cyan) {
                            HStack(spacing: 8) {
                                if noiseManager.currentNoise != .none {
                                    if noiseManager.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                    } else if noiseManager.isPlaying {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                                
                                Picker("", selection: $noiseManager.currentNoise) {
                                    ForEach(NoiseType.allCases) { noise in
                                        Text(noise.rawValue).tag(noise)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 70)
                            }
                        }
                        
                        if noiseManager.currentNoise != .none {
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Slider(value: $noiseManager.volume, in: 0...1)
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            // 退出按钮
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("退出应用")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 280, height: 380)
    }
}

// MARK: - 设置组件

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.leading, 4)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color(white: 0.15))
            .cornerRadius(12)
        }
    }
}

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder let trailing: Content
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .cornerRadius(6)
            
            Text(title)
                .font(.system(size: 14))
            
            Spacer()
            
            trailing
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(white: 0.12))
    }
}

struct DurationStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                if value > range.lowerBound {
                    value -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color(white: 0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Text("\(value)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .frame(width: 32)
            
            Button {
                if value < range.upperBound {
                    value += 1
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color(white: 0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
}
