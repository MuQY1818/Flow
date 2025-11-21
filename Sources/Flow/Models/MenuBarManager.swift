import SwiftUI
import AppKit
import Combine

class MenuBarManager: NSObject {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        super.init()
        setupStatusItem()
        setupPopover()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Create the SwiftUI view for the menu bar icon
            let iconView = MenuBarIconView(timerManager: timerManager)
            let hostingView = NSHostingView(rootView: iconView)
            
            // Set the frame for the hosting view. 
            // 60 width + padding, 22 height is standard-ish.
            hostingView.frame = NSRect(x: 0, y: 0, width: 64, height: 22)
            
            button.subviews.forEach { $0.removeFromSuperview() }
            button.addSubview(hostingView)
            
            // Add constraints to keep the hosting view centered/filling the button
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: button.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                button.widthAnchor.constraint(equalToConstant: 64) // Fixed width for now
            ])
            
            // Handle click
            button.target = self
            button.action = #selector(togglePopover(_:))
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
}
