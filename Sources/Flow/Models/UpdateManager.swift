import Foundation
import AppKit
import CryptoKit

/// 自动更新管理器 - 安全版（哈希校验 + 原子替换 + 多源支持）
class UpdateManager: NSObject, ObservableObject {
    
    static let githubRepo = "MuQY1818/Flow"
    
    static let giteeRepo = "muqyun/Flow"
    
    // 多源支持：GitHub（国际）+ Gitee（国内）
    static let sources: [(name: String, appcastURL: String, downloadBaseURL: String)] = [
        ("GitHub", "https://github.com/\(githubRepo)/releases/latest/download/appcast.xml", 
         "https://github.com/\(githubRepo)/releases/latest/download/"),
        ("Gitee", "https://gitee.com/\(giteeRepo)/releases/latest/download/appcast.xml",
         "https://gitee.com/\(giteeRepo)/releases/latest/download/")
    ]
    
    private var currentSourceIndex = 0
    
    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var isChecking = false
    @Published var updateProgress: Double = 0
    @Published var updateStatus: String = ""
    
    private var expectedSHA256: String?
    private var changeLog: String?
    
    /// 检查更新（支持多源自动切换）
    func checkForUpdates() {
        isChecking = true
        currentSourceIndex = 0
        tryCheckUpdate()
    }
    
    private func tryCheckUpdate() {
        guard currentSourceIndex < Self.sources.count else {
            DispatchQueue.main.async {
                self.isChecking = false
                self.showNoUpdateAlert()
            }
            return
        }
        
        let source = Self.sources[currentSourceIndex]
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        
        guard let url = URL(string: source.appcastURL) else {
            currentSourceIndex += 1
            tryCheckUpdate()
            return
        }
        
        // 带超时的请求配置
        var request = URLRequest(url: url)
        request.timeoutInterval = 10 // 10秒超时
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // 检查是否成功
            if let error = error {
                print("[UpdateManager] \(source.name) 失败: \(error.localizedDescription)")
                self.currentSourceIndex += 1
                self.tryCheckUpdate()
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let xmlString = String(data: data, encoding: .utf8) else {
                print("[UpdateManager] \(source.name) 响应无效，尝试下一个源")
                self.currentSourceIndex += 1
                self.tryCheckUpdate()
                return
            }
            
            // 解析版本号
            guard let version = self.parseXMLAttribute(xmlString, attribute: "sparkle:shortVersionString") else {
                self.currentSourceIndex += 1
                self.tryCheckUpdate()
                return
            }
            
            print("[UpdateManager] 使用 \(source.name) 源成功")
            
            DispatchQueue.main.async {
                self.isChecking = false
                self.latestVersion = version
                
                // 解析 SHA256 哈希值
                self.expectedSHA256 = self.parseXMLAttribute(xmlString, attribute: "sparkle:sha256")
                
                // 解析更新日志
                self.changeLog = self.parseChangeLog(xmlString)
                
                if self.compareVersions(current: currentVersion, latest: version) == .orderedAscending {
                    self.updateAvailable = true
                    self.showUpdateAlert(currentVersion: currentVersion, newVersion: version)
                } else {
                    self.showNoUpdateAlert()
                }
            }
        }.resume()
    }
    
    /// 解析 XML 属性值
    private func parseXMLAttribute(_ xml: String, attribute: String) -> String? {
        let pattern = "\(attribute)=\""
        guard let range = xml.range(of: pattern),
              let endRange = xml[range.upperBound...].range(of: "\"") else {
            return nil
        }
        return String(xml[range.upperBound..<endRange.lowerBound])
    }
    
    /// 解析更新日志
    private func parseChangeLog(_ xml: String) -> String? {
        // 查找 CDATA 内容
        guard let startRange = xml.range(of: "<![CDATA["),
              let endRange = xml.range(of: "]]>") else {
            return nil
        }
        
        let content = String(xml[startRange.upperBound..<endRange.lowerBound])
        
        // 清理 HTML 标签，提取纯文本
        var text = content
            .replacingOccurrences(of: "<h2>", with: "")
            .replacingOccurrences(of: "</h2>", with: "\n")
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除多余空行
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return text.isEmpty ? nil : text
    }
    
    /// 比较版本号
    private func compareVersions(current: String, latest: String) -> ComparisonResult {
        return current.compare(latest, options: .numeric)
    }
    
    /// 显示更新提示
    private func showUpdateAlert(currentVersion: String, newVersion: String) {
        let alert = NSAlert()
        alert.messageText = "发现新版本 v\(newVersion)"
        
        var info = "当前版本: v\(currentVersion)"
        
        // 显示更新内容
        if let log = changeLog {
            info += "\n\n\(log)"
        }
        
        info += "\n\n点击「更新」将自动下载并安装。"
        
        alert.informativeText = info
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
    
    /// 执行安全更新（使用当前成功的源）
    private func performUpdate() {
        let source = Self.sources[currentSourceIndex]
        let downloadURL = source.downloadBaseURL + "Flow.app.zip"
        print("[UpdateManager] 从 \(source.name) 下载更新")
        
        // 获取当前应用路径（动态路径，不硬编码）
        let currentAppPath = Bundle.main.bundlePath
        let currentAppURL = URL(fileURLWithPath: currentAppPath)
        let appDirectory = currentAppURL.deletingLastPathComponent()
        
        // 临时文件路径
        let tempDir = FileManager.default.temporaryDirectory
        let zipPath = tempDir.appendingPathComponent("Flow_update.zip")
        let extractPath = tempDir.appendingPathComponent("Flow_update_extracted")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // 清理旧的临时文件
                try? FileManager.default.removeItem(at: zipPath)
                try? FileManager.default.removeItem(at: extractPath)
                
                // 1. 下载 ZIP
                self.updateStatus(message: "正在下载...")
                guard let zipData = try? Data(contentsOf: URL(string: downloadURL)!) else {
                    throw UpdateError.downloadFailed
                }
                
                // 2. 哈希校验
                if let expectedHash = self.expectedSHA256 {
                    self.updateStatus(message: "正在校验...")
                    let actualHash = SHA256.hash(data: zipData).map { String(format: "%02x", $0) }.joined()
                    
                    if actualHash.lowercased() != expectedHash.lowercased() {
                        throw UpdateError.hashMismatch(expected: expectedHash, actual: actualHash)
                    }
                }
                
                // 3. 保存 ZIP 文件
                try zipData.write(to: zipPath)
                
                // 4. 解压到临时目录
                self.updateStatus(message: "正在解压...")
                try FileManager.default.createDirectory(at: extractPath, withIntermediateDirectories: true)
                
                let unzipProcess = Process()
                unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
                unzipProcess.arguments = ["-oq", zipPath.path, "-d", extractPath.path]
                try unzipProcess.run()
                unzipProcess.waitUntilExit()
                
                guard unzipProcess.terminationStatus == 0 else {
                    throw UpdateError.unzipFailed
                }
                
                // 5. 查找解压后的 .app
                let newAppURL = extractPath.appendingPathComponent("Flow.app")
                guard FileManager.default.fileExists(atPath: newAppURL.path) else {
                    throw UpdateError.appNotFound
                }
                
                // 6. 移除隔离属性（防止"无法打开"错误）
                self.updateStatus(message: "正在准备...")
                let xattrProcess = Process()
                xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                xattrProcess.arguments = ["-rd", "com.apple.quarantine", newAppURL.path]
                try? xattrProcess.run()
                xattrProcess.waitUntilExit()
                
                // 7. 原子替换（安全替换，失败不会丢失旧版本）
                self.updateStatus(message: "正在安装...")
                
                // 使用 replaceItemAt 进行原子替换
                _ = try FileManager.default.replaceItemAt(currentAppURL, withItemAt: newAppURL, backupItemName: nil, options: .usingNewMetadataOnly)
                
                // 8. 清理临时文件
                try? FileManager.default.removeItem(at: zipPath)
                try? FileManager.default.removeItem(at: extractPath)
                
                // 9. 启动新版本并退出当前应用
                self.updateStatus(message: "正在重启...")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 启动新版本
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = true
                    NSWorkspace.shared.openApplication(at: currentAppURL, configuration: config) { _, error in
                        if error != nil {
                            // 备用方案：使用 open 命令
                            let openProcess = Process()
                            openProcess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                            openProcess.arguments = [currentAppURL.path]
                            try? openProcess.run()
                        }
                    }
                    // 稍等一下再退出，确保新应用启动
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        NSApplication.shared.terminate(nil)
                    }
                }
                
            } catch {
                self.handleUpdateError(error)
            }
        }
    }
    
    /// 更新状态信息
    private func updateStatus(message: String) {
        DispatchQueue.main.async {
            self.updateStatus = message
        }
    }
    
    /// 处理更新错误
    private func handleUpdateError(_ error: Error) {
        DispatchQueue.main.async {
            let errorAlert = NSAlert()
            errorAlert.messageText = "更新失败"
            
            if let updateError = error as? UpdateError {
                errorAlert.informativeText = updateError.localizedDescription
            } else {
                errorAlert.informativeText = "发生未知错误：\(error.localizedDescription)"
            }
            
            errorAlert.informativeText += "\n\n请手动下载安装。"
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

/// 更新错误类型
enum UpdateError: LocalizedError {
    case downloadFailed
    case hashMismatch(expected: String, actual: String)
    case unzipFailed
    case appNotFound
    case replaceFailed
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "下载失败，请检查网络连接。"
        case .hashMismatch(let expected, let actual):
            return "文件校验失败，可能已损坏或被篡改。\n期望: \(expected.prefix(16))...\n实际: \(actual.prefix(16))..."
        case .unzipFailed:
            return "解压失败，下载文件可能已损坏。"
        case .appNotFound:
            return "解压后未找到应用程序。"
        case .replaceFailed:
            return "替换应用失败，请检查权限。"
        }
    }
}
