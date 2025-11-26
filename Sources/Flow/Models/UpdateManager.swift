import Foundation
import AppKit

/// 自动更新管理器 - 简化版（无需代码签名）
class UpdateManager: NSObject, ObservableObject {
    
    static let githubRepo = "MuQY1818/Flow"
    static let appcastURL = "https://github.com/\(githubRepo)/releases/latest/download/appcast.xml"
    
    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var isChecking = false
    
    /// 检查更新
    func checkForUpdates() {
        isChecking = true
        
        // 获取当前版本
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        
        // 从 appcast.xml 获取最新版本
        guard let url = URL(string: Self.appcastURL) else {
            isChecking = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isChecking = false
                
                guard let data = data, error == nil,
                      let xmlString = String(data: data, encoding: .utf8) else {
                    self?.showNoUpdateAlert()
                    return
                }
                
                // 简单解析 XML 获取版本号
                if let range = xmlString.range(of: "sparkle:shortVersionString=\""),
                   let endRange = xmlString[range.upperBound...].range(of: "\"") {
                    let version = String(xmlString[range.upperBound..<endRange.lowerBound])
                    self?.latestVersion = version
                    
                    if self?.compareVersions(current: currentVersion, latest: version) == .orderedAscending {
                        self?.updateAvailable = true
                        self?.showUpdateAlert(currentVersion: currentVersion, newVersion: version)
                    } else {
                        self?.showNoUpdateAlert()
                    }
                }
            }
        }.resume()
    }
    
    /// 比较版本号
    private func compareVersions(current: String, latest: String) -> ComparisonResult {
        return current.compare(latest, options: .numeric)
    }
    
    /// 显示更新提示
    private func showUpdateAlert(currentVersion: String, newVersion: String) {
        let alert = NSAlert()
        alert.messageText = "发现新版本 v\(newVersion)"
        alert.informativeText = "当前版本: v\(currentVersion)\n\n点击「更新」将自动下载并安装新版本。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "更新")
        alert.addButton(withTitle: "稍后")
        
        if alert.runModal() == .alertFirstButtonReturn {
            performUpdate()
        }
    }
    
    /// 显示无更新提示
    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "已是最新版本"
        alert.informativeText = "当前版本已是最新，无需更新。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
    
    /// 执行更新
    private func performUpdate() {
        let downloadURL = "https://github.com/\(Self.githubRepo)/releases/latest/download/Flow.app.zip"
        
        // 创建更新脚本
        let script = """
        #!/bin/bash
        echo "正在下载更新..."
        curl -sL "\(downloadURL)" -o /tmp/Flow.zip
        echo "正在安装..."
        unzip -oq /tmp/Flow.zip -d /tmp
        rm -rf /Applications/Flow.app
        mv /tmp/Flow.app /Applications/
        rm /tmp/Flow.zip
        echo "更新完成！正在重启..."
        open /Applications/Flow.app
        """
        
        // 保存脚本
        let scriptPath = "/tmp/flow_update.sh"
        try? script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        
        // 在终端中运行（需要用户确认）
        let appleScript = """
        tell application "Terminal"
            activate
            do script "bash \(scriptPath)"
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            scriptObject.executeAndReturnError(&error)
        }
        
        // 退出当前应用
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApplication.shared.terminate(nil)
        }
    }
}
