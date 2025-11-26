import Foundation
import Sparkle

/// 自动更新管理器 - 使用 Sparkle 框架
class UpdateManager: NSObject, ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    @Published var lastUpdateCheck: Date?
    
    // GitHub Release 的 appcast URL
    // 格式: https://raw.githubusercontent.com/{用户名}/{仓库名}/main/appcast.xml
    static let appcastURL = "https://raw.githubusercontent.com/MuQY1818/Flow/main/appcast.xml"
    
    override init() {
        // 创建更新控制器
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        super.init()
        
        // 监听更新器状态
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
    
    /// 检查更新
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    /// 获取更新器
    var updater: SPUUpdater {
        updaterController.updater
    }
}
