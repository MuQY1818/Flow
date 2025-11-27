import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShareCardView: View {
    @EnvironmentObject var timerManager: TimerManager
    let dailyDuration: TimeInterval
    let sessionCount: Int
    
    private let gradientColors = [
        Color(red: 0.1, green: 0.1, blue: 0.12),
        Color(red: 0.05, green: 0.05, blue: 0.07)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image("AppIcon") // Assuming AppIcon is available, or use system image
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Flow")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text(Date(), style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Stats
            VStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("今日专注")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(2)
                    
                    let components = dailyDuration.focusTimeComponents()
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(components.hours)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("h")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(components.minutes)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("m")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        Text("\(sessionCount) 次专注")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        Text("保持心流")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(.vertical, 20)
            
            Spacer()
            
            // Footer with QR Code
            HStack(spacing: 16) {
                if let qrCode = QRCodeGenerator.generate(from: "https://github.com/MuQY1818/Flow") {
                    Image(nsImage: qrCode)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("GitHub")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("MuQY1818/Flow")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("扫码获取同款专注工具")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.top, 2)
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(white: 0.08))
            .cornerRadius(12)
        }
        .padding(24)
        .frame(width: 300, height: 450)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct QRCodeGenerator {
    static func generate(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            // Scale up the image to make it sharp
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return NSImage(cgImage: cgImage, size: NSSize(width: 200, height: 200))
            }
        }
        return nil
    }
}

// Extension to help view extraction for image generation
extension View {
    func snapshot() -> NSImage? {
        let controller = NSHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.fittingSize
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.frame = CGRect(origin: .zero, size: targetSize)
        
        // Force layout
        view.layoutSubtreeIfNeeded()
        
        let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: bitmapRep)
        
        let image = NSImage(size: targetSize)
        image.addRepresentation(bitmapRep)
        return image
    }
}
