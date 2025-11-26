import SwiftUI
import AppKit
import Combine

class FloatingWindowController: NSObject {
    private var window: NSWindow?
    private var timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isVisible: Bool = false {
        didSet {
            UserDefaults.standard.set(isVisible, forKey: "floatingBallVisible")
            updateVisibility()
        }
    }
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        super.init()
        
        // Load saved visibility state
        isVisible = UserDefaults.standard.bool(forKey: "floatingBallVisible")
        
        setupWindow()
    }
    
    private func setupWindow() {
        // Create borderless, transparent window
        // 增加高度以容纳下拉菜单
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 320),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Window properties
        window.level = .floating  // Always on top
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.isMovableByWindowBackground = true  // Enable dragging
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Position window at saved location or default to top-right
        let savedX = UserDefaults.standard.double(forKey: "floatingBallX")
        let savedY = UserDefaults.standard.double(forKey: "floatingBallY")
        
        if savedX != 0 || savedY != 0 {
            window.setFrameOrigin(NSPoint(x: savedX, y: savedY))
        } else {
            // Default position: top-right corner
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.maxX - 130
                let y = screenFrame.maxY - 130
                window.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
        
        // Set up SwiftUI content with hide callback
        let floatingBallView = FloatingBallView(
            timerManager: timerManager,
            onHide: { [weak self] in
                self?.hide()
            }
        )
        let hostingView = NSHostingView(rootView: floatingBallView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 160, height: 320)
        
        window.contentView = hostingView
        
        self.window = window
        
        // Save position when window moves
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )
        
        updateVisibility()
    }
    
    @objc private func windowDidMove(_ notification: Notification) {
        guard let window = window else { return }
        UserDefaults.standard.set(window.frame.origin.x, forKey: "floatingBallX")
        UserDefaults.standard.set(window.frame.origin.y, forKey: "floatingBallY")
    }
    
    private func updateVisibility() {
        if isVisible {
            window?.orderFront(nil)
        } else {
            window?.orderOut(nil)
        }
    }
    
    func toggle() {
        isVisible.toggle()
    }
    
    func show() {
        isVisible = true
    }
    
    func hide() {
        isVisible = false
    }
}
