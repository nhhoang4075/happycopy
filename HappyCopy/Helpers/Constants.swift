//
//  Constants.swift
//  HappyCopy
//
//  Created by Nguyen Huy Hoang on 4/11/25.
//

import Foundation

struct AppInfo {
    static var name: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
        ?? "Clipboard"
    }
    
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var fullVersion: String {
        "\(version).\(build)"
    }
}
