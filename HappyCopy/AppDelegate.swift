//
//  AppDelegate.swift
//  HappyCopy
//
//  Created by Nguyen Huy Hoang on 3/11/25.
//

import SwiftUI
import AppKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var monitor = ClipboardMonitor()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                return
            } else {
                return
            }
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkle.text.clipboard.fill", accessibilityDescription: AppInfo.name)
            button.action = #selector(togglePopover)
        }
        
        popover.contentSize = NSSize(width: 350, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(monitor: monitor))
        
        monitor.startMonitoring()
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                self.popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
