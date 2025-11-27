import SwiftUI
import AppKit
import Combine

class MenuBarManager: NSObject {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var timerManager: TimerManager
    var floatingWindowController: FloatingWindowController
    var updateManager: UpdateManager
    private var cancellables = Set<AnyCancellable>()
    
    init(timerManager: TimerManager, floatingWindowController: FloatingWindowController, updateManager: UpdateManager) {
        self.timerManager = timerManager
        self.floatingWindowController = floatingWindowController
        self.updateManager = updateManager
        super.init()
        setupStatusItem()
        setupPopover()
        setupRightClickMenu()
    }
    
    private func setupStatusItem() {
        // Remove existing status item if any
        if let existingItem = statusItem {
            NSStatusBar.system.removeStatusItem(existingItem)
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Create the SwiftUI view for the menu bar icon
            let iconView = MenuBarIconView(timerManager: timerManager)
            let hostingView = NSHostingView(rootView: iconView)
            
            // Set width based on style
            let width: CGFloat = timerManager.useCompactMenuBar ? 70 : 74
            hostingView.frame = NSRect(x: 0, y: 0, width: width, height: 22)
            
            button.subviews.forEach { $0.removeFromSuperview() }
            button.addSubview(hostingView)
            
            // Add constraints to keep the hosting view centered/filling the button
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: button.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                button.widthAnchor.constraint(equalToConstant: width)
            ])
            
            // Handle click (left click = popover, right click = menu)
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 600, height: 450)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView().environmentObject(timerManager))
        self.popover = popover
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Bring app to front so the popover is active
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func setupRightClickMenu() {
        let menu = NSMenu()
        
        // Toggle floating ball
        let floatingItem = NSMenuItem(
            title: "显示悬浮球",
            action: #selector(toggleFloatingBall),
            keyEquivalent: "f"
        )
        floatingItem.target = self
        menu.addItem(floatingItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = nil // We handle menu manually on right-click
        
        // Store menu for right-click
        if let button = statusItem?.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Show context menu
            let menu = createContextMenu()
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            togglePopover(sender)
        }
    }
    
    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Toggle floating ball
        let floatingItem = NSMenuItem(
            title: floatingWindowController.isVisible ? "隐藏悬浮球" : "显示悬浮球",
            action: #selector(toggleFloatingBall),
            keyEquivalent: ""
        )
        floatingItem.target = self
        menu.addItem(floatingItem)
        
        // Toggle menu bar style
        let menuBarStyleItem = NSMenuItem(
            title: timerManager.useCompactMenuBar ? "切换到胶囊样式" : "切换到紧凑样式",
            action: #selector(toggleMenuBarStyle),
            keyEquivalent: ""
        )
        menuBarStyleItem.target = self
        menu.addItem(menuBarStyleItem)
        
        // Settings
        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Check for updates
        let updateItem = NSMenuItem(
            title: "检查更新...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc private func toggleFloatingBall() {
        floatingWindowController.toggle()
    }
    
    @objc private func toggleMenuBarStyle() {
        timerManager.useCompactMenuBar.toggle()
        // Refresh the status item
        setupStatusItem()
    }
    
    @objc private func checkForUpdates() {
        updateManager.checkForUpdates()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func openSettings() {
        // Open popover and show settings
        timerManager.shouldShowSettings = true
        if let button = statusItem?.button {
            togglePopover(button)
        }
    }
}
