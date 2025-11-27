import SwiftUI
import CoreImage.CIFilterBuiltins
import AppKit

struct ShareCardView: View {
    @EnvironmentObject var timerManager: TimerManager
    let dailyDuration: TimeInterval
    let sessionCount: Int
    
    var body: some View {
        ZStack {
            // 多层渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 微妙的光晕效果
            RadialGradient(
                colors: [
                    Color.green.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 200
            )
            .offset(y: -30)
            
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    // App Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), Color.blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Flow")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text(formattedDate)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                
                Spacer()
                
                // 主要数据展示
                VStack(spacing: 8) {
                    Text("今日专注")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(3)
                    
                    let components = dailyDuration.focusTimeComponents()
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(components.hours)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Text("h")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .offset(y: 8)
                        
                        Text("\(String(format: "%02d", components.minutes))")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .padding(.leading, 4)
                        Text("m")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .offset(y: 8)
                    }
                }
                
                // 统计徽章
                HStack(spacing: 20) {
                    StatBadge(icon: "flame.fill", color: .orange, value: "\(sessionCount)", label: "次专注")
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 40)
                    
                    StatBadge(icon: "bolt.fill", color: .yellow, value: "心流", label: "状态")
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Footer with QR Code
                HStack(spacing: 14) {
                    if let qrCode = QRCodeGenerator.generate(from: "https://github.com/MuQY1818/Flow") {
                        Image(nsImage: qrCode)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 56, height: 56)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            Text("GitHub")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("MuQY1818/Flow")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 320, height: 440)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: Date())
    }
}

// 统计徽章组件
struct StatBadge: View {
    let icon: String
    let color: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

struct QRCodeGenerator {
    static func generate(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // Scale up the image to make it sharp (higher scale for better quality)
            let transform = CGAffineTransform(scaleX: 20, y: 20)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return NSImage(cgImage: cgImage, size: NSSize(width: 400, height: 400))
            }
        }
        return nil
    }
}

// High-resolution snapshot extension for ShareCardView
extension View {
    @MainActor
    func snapshot(scale: CGFloat = 2.0) -> NSImage? {
        // 使用 ImageRenderer (macOS 13+)
        let renderer = ImageRenderer(content: self.environment(\.colorScheme, .dark))
        renderer.scale = scale
        
        if let nsImage = renderer.nsImage {
            return nsImage
        }
        
        // Fallback: 使用 NSHostingController
        let controller = NSHostingController(rootView: self.environment(\.colorScheme, .dark))
        let view = controller.view
        
        // 使用固定尺寸而不是 fittingSize
        let targetSize = NSSize(width: 320, height: 440)
        view.frame = NSRect(origin: .zero, size: targetSize)
        view.bounds = NSRect(origin: .zero, size: targetSize)
        
        // Force layout
        view.layoutSubtreeIfNeeded()
        
        // 使用 cacheDisplay 方法
        guard let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            return nil
        }
        view.cacheDisplay(in: view.bounds, to: bitmapRep)
        
        let image = NSImage(size: targetSize)
        image.addRepresentation(bitmapRep)
        
        return image
    }
}
