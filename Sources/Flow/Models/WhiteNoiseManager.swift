import Foundation
import AVFoundation
import Combine

/// 白噪音类型
enum NoiseType: String, CaseIterable, Identifiable {
    case none = "关闭"
    case whiteNoise = "白噪音"
    case pinkNoise = "粉红噪音"
    case brownNoise = "棕噪音"
    case rain = "雨声"
    case ocean = "海浪"
    case forest = "森林"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .whiteNoise: return "waveform"
        case .pinkNoise: return "waveform.circle"
        case .brownNoise: return "waveform.circle.fill"
        case .rain: return "cloud.rain"
        case .ocean: return "water.waves"
        case .forest: return "leaf"
        }
    }
}

/// 白噪音管理器
class WhiteNoiseManager: ObservableObject {
    static let shared = WhiteNoiseManager()
    
    @Published var currentNoise: NoiseType = .none {
        didSet {
            if currentNoise != oldValue {
                stopNoise()
                if currentNoise != .none {
                    startNoise()
                }
                UserDefaults.standard.set(currentNoise.rawValue, forKey: "selectedNoise")
            }
        }
    }
    
    @Published var volume: Float = 0.5 {
        didSet {
            playerNode?.volume = volume
            UserDefaults.standard.set(volume, forKey: "noiseVolume")
        }
    }
    
    @Published var isPlaying = false
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var noiseBuffer: AVAudioPCMBuffer?
    
    private init() {
        // 恢复上次设置
        if let savedNoise = UserDefaults.standard.string(forKey: "selectedNoise"),
           let noise = NoiseType(rawValue: savedNoise) {
            currentNoise = noise
        }
        volume = UserDefaults.standard.float(forKey: "noiseVolume")
        if volume == 0 { volume = 0.5 }
    }
    
    /// 开始播放噪音
    func startNoise() {
        guard currentNoise != .none else { return }
        
        stopNoise()
        
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let player = playerNode else { return }
        
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        // 生成噪音缓冲区
        noiseBuffer = generateNoiseBuffer(type: currentNoise, format: format, duration: 2.0)
        
        guard let buffer = noiseBuffer else { return }
        
        do {
            try engine.start()
            player.volume = volume
            
            // 循环播放
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    /// 停止播放
    func stopNoise() {
        playerNode?.stop()
        audioEngine?.stop()
        playerNode = nil
        audioEngine = nil
        noiseBuffer = nil
        
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    /// 生成噪音缓冲区
    private func generateNoiseBuffer(type: NoiseType, format: AVAudioFormat, duration: Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return nil }
        
        switch type {
        case .whiteNoise:
            generateWhiteNoise(left: leftChannel, right: rightChannel, frames: frameCount)
        case .pinkNoise:
            generatePinkNoise(left: leftChannel, right: rightChannel, frames: frameCount)
        case .brownNoise:
            generateBrownNoise(left: leftChannel, right: rightChannel, frames: frameCount)
        case .rain:
            generateRainSound(left: leftChannel, right: rightChannel, frames: frameCount, sampleRate: format.sampleRate)
        case .ocean:
            generateOceanSound(left: leftChannel, right: rightChannel, frames: frameCount, sampleRate: format.sampleRate)
        case .forest:
            generateForestSound(left: leftChannel, right: rightChannel, frames: frameCount, sampleRate: format.sampleRate)
        case .none:
            break
        }
        
        return buffer
    }
    
    // MARK: - 噪音生成算法
    
    private func generateWhiteNoise(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        for i in 0..<Int(frames) {
            let sample = Float.random(in: -0.3...0.3)
            left[i] = sample
            right[i] = sample * 0.95 + Float.random(in: -0.02...0.02) // 轻微立体声效果
        }
    }
    
    private func generatePinkNoise(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
        
        for i in 0..<Int(frames) {
            let white = Float.random(in: -1...1)
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            let pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11
            b6 = white * 0.115926
            left[i] = pink * 0.5
            right[i] = pink * 0.5 + Float.random(in: -0.01...0.01)
        }
    }
    
    private func generateBrownNoise(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount) {
        var lastOut: Float = 0
        
        for i in 0..<Int(frames) {
            let white = Float.random(in: -1...1)
            lastOut = (lastOut + (0.02 * white)) / 1.02
            let brown = lastOut * 3.5
            left[i] = brown * 0.5
            right[i] = brown * 0.5 + Float.random(in: -0.01...0.01)
        }
    }
    
    private func generateRainSound(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount, sampleRate: Double) {
        var lastOut: Float = 0
        
        for i in 0..<Int(frames) {
            // 基础噪音（粉红噪音为底）
            let white = Float.random(in: -1...1)
            lastOut = (lastOut + (0.02 * white)) / 1.02
            var sample = lastOut * 2.0
            
            // 添加随机"雨滴"效果
            if Float.random(in: 0...1) < 0.003 {
                sample += Float.random(in: 0.1...0.3) * (Float.random(in: 0...1) > 0.5 ? 1 : -1)
            }
            
            left[i] = sample * 0.4
            right[i] = sample * 0.4 + Float.random(in: -0.02...0.02)
        }
    }
    
    private func generateOceanSound(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount, sampleRate: Double) {
        var phase: Double = 0
        var lastOut: Float = 0
        
        for i in 0..<Int(frames) {
            // 低频波浪
            let wave = sin(phase) * 0.3
            phase += 0.3 / sampleRate * 2 * .pi
            
            // 棕噪音作为海浪声
            let white = Float.random(in: -1...1)
            lastOut = (lastOut + (0.02 * white)) / 1.02
            let noise = lastOut * 2.5
            
            // 组合
            let sample = Float(wave) + noise * (0.3 + Float(sin(phase * 0.1)) * 0.2)
            left[i] = sample * 0.35
            right[i] = sample * 0.35 + Float.random(in: -0.02...0.02)
        }
    }
    
    private func generateForestSound(left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>, frames: AVAudioFrameCount, sampleRate: Double) {
        var lastOut: Float = 0
        var birdPhase: Double = 0
        
        for i in 0..<Int(frames) {
            // 轻柔的风声（粉红噪音）
            let white = Float.random(in: -1...1)
            lastOut = (lastOut + (0.015 * white)) / 1.015
            var sample = lastOut * 1.5
            
            // 偶尔的鸟叫声（高频）
            if Float.random(in: 0...1) < 0.0001 {
                birdPhase = Double.random(in: 500...2000)
            }
            if birdPhase > 0 {
                sample += Float(sin(birdPhase * Double(i) / sampleRate * 2 * .pi)) * 0.1
                birdPhase *= 0.9999
            }
            
            left[i] = sample * 0.3
            right[i] = sample * 0.3 + Float.random(in: -0.015...0.015)
        }
    }
}
