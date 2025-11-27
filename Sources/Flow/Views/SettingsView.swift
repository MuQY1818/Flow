import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject private var noiseManager = WhiteNoiseManager.shared
    @State private var quitHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            Text("设置")
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)
            
            // 设置列表
            VStack(spacing: 20) {
                // 时长设置
                SettingsGroup(title: "时长") {
                    SettingItem(icon: "flame.fill", color: .green, title: "专注") {
                        StepperControl(value: $timerManager.focusDuration, unit: "分钟")
                    }
                    SettingItem(icon: "cup.and.saucer.fill", color: .blue, title: "短休息") {
                        StepperControl(value: $timerManager.shortBreakDuration, unit: "分钟")
                    }
                    SettingItem(icon: "moon.fill", color: .purple, title: "长休息") {
                        StepperControl(value: $timerManager.longBreakDuration, unit: "分钟")
                    }
                }
                
                // 声音设置
                SettingsGroup(title: "声音") {
                    SettingItem(icon: "bell.fill", color: .orange, title: "提示音") {
                        Toggle("", isOn: $timerManager.isSoundEnabled)
                            .toggleStyle(.switch)
                            .scaleEffect(0.75)
                            .frame(width: 44)
                    }
                    
                    SettingItem(icon: "waveform", color: .cyan, title: "白噪音") {
                        HStack(spacing: 6) {
                            if noiseManager.isPlaying {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                            }
                            Picker("", selection: $noiseManager.currentNoise) {
                                ForEach(NoiseType.allCases) { noise in
                                    Text(noise.rawValue).tag(noise)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 65)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // 退出按钮
            HoverButton(
                title: "退出应用",
                icon: "power",
                color: .red
            ) {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 260, height: 340)
    }
}

// MARK: - 设置组

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray.opacity(0.8))
                .padding(.leading, 2)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(white: 0.13))
            .cornerRadius(10)
        }
    }
}

// MARK: - 设置项

struct SettingItem<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    @ViewBuilder let control: Content
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.15))
                .cornerRadius(5)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            control
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

// MARK: - 步进控制

struct StepperControl: View {
    @Binding var value: Int
    let unit: String
    @State private var minusHovered = false
    @State private var plusHovered = false
    
    var body: some View {
        HStack(spacing: 4) {
            // 减少按钮
            Button {
                if value > 1 { value -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(minusHovered ? .white : .gray)
                    .frame(width: 20, height: 20)
                    .background(minusHovered ? Color.white.opacity(0.2) : Color(white: 0.2))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.15)) { minusHovered = h } }
            
            // 数值
            Text("\(value)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 28)
            
            // 增加按钮
            Button {
                if value < 120 { value += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(plusHovered ? .white : .gray)
                    .frame(width: 20, height: 20)
                    .background(plusHovered ? Color.white.opacity(0.2) : Color(white: 0.2))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.15)) { plusHovered = h } }
        }
    }
}

// MARK: - 悬停按钮

struct HoverButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isHovered ? .white : color.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(isHovered ? color.opacity(0.3) : color.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
