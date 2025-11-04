//
//  SettingsView.swift
//  HappyCopy
//
//  Created by Nguyen Huy Hoang on 3/11/25.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
            
                Text(AppInfo.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
            }
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 24) {
                settingsSection(title: "General") {
                    Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                        .onChange(of: settings.launchAtLogin) { _, newValue in
                            setLaunchAtLogin(enabled: newValue)
                        }
                    
                    Toggle("Show Notifications", isOn: $settings.showNotifications)
                }
                
                Divider()
                
                settingsSection(title: "Storage") {
                    HStack {
                        Text("Maximun Items")
                        Picker("", selection: $settings.maxItems) {
                            Text("50").tag(50)
                            Text("100").tag(100)
                            Text("200").tag(200)
                            Text("500").tag(500)
                        }
                        .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Auto-delete after")
                        Picker("", selection: $settings.autoDeleteAfterDays) {
                            Text("1 day").tag(1)
                            Text("3 days").tag(3)
                            Text("7 days").tag(7)
                            Text("30 days").tag(30)
                            Text("Never").tag(0)
                        }
                        .frame(width: 100)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Button (action: quitApp) {
                        HStack {
                            Image(systemName: "power")
                            Text("Quit \(AppInfo.name)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .keyboardShortcut("q", modifiers: .command)
                    
                    Text("Version: \(AppInfo.fullVersion)")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
        }
        .frame(width: 400)
        .navigationTitle("")
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
        }
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(monitor: ClipboardMonitor())
            .frame(width: 400)
    }
}
