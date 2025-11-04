//
//  ClipboardSettings.swift
//  HappyCopy
//
//  Created by Nguyen Huy Hoang on 3/11/25.
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")}
    }
    
    @Published var maxItems: Int {
        didSet {
            UserDefaults.standard.set(maxItems, forKey: "maxItems")
            NotificationCenter.default.post(name: .maxItemsChanged, object: maxItems)
        }
    }
    
    @Published var autoDeleteAfterDays: Int {
        didSet { UserDefaults.standard.set(autoDeleteAfterDays, forKey: "autoDeleteAfterDays")}
    }
    
    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: "showNotifications")
        }
    }
    
    private init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        
        if let savedMaxItems = UserDefaults.standard.object(forKey: "maxItems") as? Int {
            self.maxItems = savedMaxItems
        } else {
            self.maxItems = 100
        }
    
        if let savedAutoDelete = UserDefaults.standard.object(forKey: "autoDeleteAfterDays") as? Int {
            self.autoDeleteAfterDays = savedAutoDelete
        } else {
            self.autoDeleteAfterDays = 7
        }
        
        self.showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")
    }
}

extension Notification.Name {
    static let maxItemsChanged = Notification.Name("maxItemsChanged")
}
