import Foundation
import AVFoundation
import Combine

/// 白噪音类型
enum NoiseType: String, CaseIterable, Identifiable {
    case none = "关闭"
    case ocean = "海浪"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .ocean: return "water.waves"
        }
    }
    
    /// 在线音频 URL（已验证可用）
    var audioURL: URL? {
        switch self {
        case .ocean:
            return URL(string: "https://cdn.pixabay.com/audio/2022/06/07/audio_b9bd4170e4.mp3")
        case .none:
            return nil
        }
    }
}

/// 白噪音管理器 - 在线音频版
class WhiteNoiseManager: NSObject, ObservableObject {
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
            player?.volume = volume
            UserDefaults.standard.set(volume, forKey: "noiseVolume")
        }
    }
    
    @Published var isPlaying = false
    @Published var isLoading = false
    
    private var player: AVPlayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    private override init() {
        super.init()
        // 恢复上次设置
        if let savedNoise = UserDefaults.standard.string(forKey: "selectedNoise"),
           let noise = NoiseType(rawValue: savedNoise) {
            currentNoise = noise
        }
        volume = UserDefaults.standard.float(forKey: "noiseVolume")
        if volume == 0 { volume = 0.5 }
    }
    
    /// 开始播放在线音频
    func startNoise() {
        guard currentNoise != .none, let url = currentNoise.audioURL else { return }
        
        stopNoise()
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        // 创建播放器
        playerItem = AVPlayerItem(url: url)
        queuePlayer = AVQueuePlayer(playerItem: playerItem!)
        playerLooper = AVPlayerLooper(player: queuePlayer!, templateItem: playerItem!)
        
        queuePlayer?.volume = volume
        
        // 监听播放状态
        playerItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        queuePlayer?.play()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status", let item = object as? AVPlayerItem {
            DispatchQueue.main.async {
                self.isLoading = false
                if item.status == .readyToPlay {
                    self.isPlaying = true
                } else if item.status == .failed {
                    self.isPlaying = false
                    print("播放失败: \(item.error?.localizedDescription ?? "未知错误")")
                }
            }
        }
    }
    
    /// 停止播放
    func stopNoise() {
        playerItem?.removeObserver(self, forKeyPath: "status")
        queuePlayer?.pause()
        playerLooper = nil
        queuePlayer = nil
        playerItem = nil
        
        DispatchQueue.main.async {
            self.isPlaying = false
            self.isLoading = false
        }
    }
    
    deinit {
        stopNoise()
    }
}
