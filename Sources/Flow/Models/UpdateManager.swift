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
        
        // 显示进度提示
        let progressAlert = NSAlert()
        progressAlert.messageText = "正在更新..."
        progressAlert.informativeText = "下载并安装中，请稍候..."
        progressAlert.alertStyle = .informational
        progressAlert.addButton(withTitle: "后台进行")
        
        // 在后台执行更新
        DispatchQueue.global(qos: .userInitiated).async {
            // 下载
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = ["-c", """
                curl -sL "\(downloadURL)" -o /tmp/Flow.zip && \
                unzip -oq /tmp/Flow.zip -d /tmp && \
                rm -rf /Applications/Flow.app && \
                mv /tmp/Flow.app /Applications/ && \
                rm /tmp/Flow.zip && \
                open /Applications/Flow.app
            """]
            
            do {
                try task.run()
                task.waitUntilExit()
                
                DispatchQueue.main.async {
                    // 更新完成，退出当前应用
                    NSApplication.shared.terminate(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "更新失败"
                    errorAlert.informativeText = "请手动下载安装：\nhttps://github.com/\(Self.githubRepo)/releases"
                    errorAlert.alertStyle = .warning
                    errorAlert.addButton(withTitle: "打开下载页")
                    errorAlert.addButton(withTitle: "取消")
                    
                    if errorAlert.runModal() == .alertFirstButtonReturn {
                        if let url = URL(string: "https://github.com/\(Self.githubRepo)/releases") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
        
        progressAlert.runModal()
    }
}
