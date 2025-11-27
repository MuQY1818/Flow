import Foundation
import AVFoundation
import Combine

/// 白噪音类型
enum NoiseType: String, CaseIterable, Identifiable {
    case none = "关闭"
    case rain = "雨声"
    case ocean = "海浪"
    case forest = "森林"
    case fire = "篝火"
    case cafe = "咖啡馆"
    case night = "夏夜虫鸣"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .ocean: return "water.waves"
        case .forest: return "leaf"
        case .fire: return "flame"
        case .cafe: return "cup.and.saucer"
        case .night: return "moon.stars"
        }
    }
    
    /// 在线音频 URL（使用免费音效）
    var audioURL: URL? {
        let urls: [NoiseType: String] = [
            .rain: "https://cdn.pixabay.com/audio/2022/10/30/audio_f4f7e09b0b.mp3",
            .ocean: "https://cdn.pixabay.com/audio/2022/06/07/audio_b9bd4170e4.mp3",
            .forest: "https://cdn.pixabay.com/audio/2022/03/12/audio_b4f7e5a4b3.mp3",
            .fire: "https://cdn.pixabay.com/audio/2021/08/04/audio_c6d5b5a830.mp3",
            .cafe: "https://cdn.pixabay.com/audio/2022/10/16/audio_7793a9ce7b.mp3",
            .night: "https://cdn.pixabay.com/audio/2024/04/11/audio_d02f7bd3ec.mp3"
        ]
        guard let urlString = urls[self] else { return nil }
        return URL(string: urlString)
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
