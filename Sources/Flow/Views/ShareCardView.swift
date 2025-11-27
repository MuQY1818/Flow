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

// High-resolution snapshot extension
extension View {
    func snapshot(scale: CGFloat = 2.0) -> NSImage? {
        let controller = NSHostingController(rootView: self.environment(\.colorScheme, .dark))
        let view = controller.view
        
        let targetSize = controller.view.fittingSize
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.frame = CGRect(origin: .zero, size: targetSize)
        
        // Force layout
        view.layoutSubtreeIfNeeded()
        
        // Create high-resolution image
        let scaledSize = NSSize(width: targetSize.width * scale, height: targetSize.height * scale)
        let image = NSImage(size: scaledSize)
        
        image.lockFocus()
        if let context = NSGraphicsContext.current {
            context.imageInterpolation = .high
            
            // Scale the context for high DPI rendering
            let transform = NSAffineTransform()
            transform.scale(by: scale)
            transform.concat()
            
            // Draw the view
            if let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: bitmapRep)
                bitmapRep.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
        image.unlockFocus()
        
        return image
    }
}
