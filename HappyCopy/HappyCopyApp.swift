//
//  HappyCopyApp.swift
//  HappyCopy
//
//  Created by Nguyen Huy Hoang on 3/11/25.
//

import SwiftUI

@main
struct HappyCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView(monitor: appDelegate.monitor)
        }
    }
}
