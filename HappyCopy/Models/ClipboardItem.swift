//
//  ClipboardItem.swift
//  HappyCopy
//
//  Created by Nguyen Huy Hoang on 3/11/25.
//

import Foundation
import AppKit

enum ClipboardItemType: String, Codable {
    case text
    case url
    case image
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let timestamp: Date
    
    // Content
    let text: String?
    let imageData: Data?
    
    var imageFormat: String?
    var isCompressed: Bool?
    
    var preview: String {
        switch type {
        case .text:
            return text ?? ""
        case .url:
            if let text = text, let url = URL(string: text) {
                return url.host ?? text
            }
            
            return text ?? String(localized: "URL")
        case .image:
            var previewText: String
            if let data = imageData, let image = NSImage(data: data) {
                let size = image.size
                
                if let format = imageFormat {
                    previewText = "\(format) \(Int(size.width))x\(Int(size.height))"
                } else {
                    previewText = String(localized:"Image \(Int(size.width))x\(Int(size.height))")
                }
            } else {
                previewText =  String(localized: "Image")
            }
            
            if self.isCompressed ?? false {
                previewText += " (\(String(localized: "Compressed")))"
            }
            
            return previewText
        }
    }
    
    init(text: String) {
        self.id = UUID()
        self.type = .text
        self.timestamp = Date()
        self.text = text
        self.imageData = nil
    }
    
    init(url: String) {
        self.id = UUID()
        self.type = .url
        self.timestamp = Date()
        self.text = url
        self.imageData = nil
    }
    
    init(image: NSImage) {
        self.id = UUID()
        self.type = .image
        self.timestamp = Date()
        self.text = nil
        
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:])
        {
            if pngData.count > 5_000_000 {
                self.imageData = compressImage(bitmap, maxBytes: 5_000_000)
                self.isCompressed = true
            } else {
                self.imageData = pngData
                self.isCompressed = false
            }
        } else {
            self.imageData = nil
        }
    }
    
    init(image: NSImage, format: String) {
        self.id = UUID()
        self.type = .image
        self.timestamp = Date()
        self.imageFormat = normalizeImageFormat(format)
        self.text = nil
        
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:])
        {
            if pngData.count > 5_000_000 {
                self.imageData = compressImage(bitmap, maxBytes: 5_000_000)
                self.isCompressed = true
            } else {
                self.imageData = pngData
                self.isCompressed = false
            }
        } else {
            self.imageData = nil
        }
    }
    
    var timeAgo: String {
        let seconds = Date().timeIntervalSince(timestamp)
        
        if seconds < 60 {
            return String(localized: "Just now")
        }
        
        if seconds < 3_600 {
            let minutes = Int(seconds / 60)
            return String(localized: "\(minutes)m ago")
        }
        
        if seconds < 86_400 {
            let hours = Int(seconds / 3600)
            return String(localized: "\(hours)h ago")
        }
        
        let days = Int(seconds / 86_400)
        return String(localized: "\(days)d ago")
    }
    
    var image: NSImage? {
        guard type == .image, let data = imageData else { return nil }
        return NSImage(data: data)
    }
}

private func compressImage(_ bitmap: NSBitmapImageRep, maxBytes: Int) -> Data? {
    for quality in stride(from: 1.0, through: 0.1, by: -0.1) {
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: quality
        ]
        
        if let compressed = bitmap.representation(using: .jpeg, properties: properties), compressed.count <= maxBytes {
            return compressed
        }
    }
    
    return nil
}

private func normalizeImageFormat(_ format: String) -> String {
    let normalized = format.lowercased()
    
    switch normalized {
    case "jpg", "jpeg":
        return "JPEG"
    case "png":
        return "PNG"
    case "gif":
        return "GIF"
    case "heic", "heif":
        return "HEIC"
    case "tiff", "tif":
        return "TIFF"
    case "icns":
        return "ICNS"
    case "webp":
        return "WebP"
    default:
        return format.uppercased()
    }
}
