//
//  ClipboardMonitor.swift
//  HappyCopy
//
//  Created by Nguyen Huy Hoang on 3/11/25.
//

import AppKit
import Combine
import UserNotifications

class ClipboardMonitor: ObservableObject {
    @Published var items: [ClipboardItem] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int
    private var maxItems: Int {
        AppSettings.shared.maxItems
    }
    
    private var hasNotifiedNearMax = false
    
    init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        
        loadFromDisk()
        
        NotificationCenter.default.addObserver(self, selector: #selector(maxItemsDidChange), name: .maxItemsChanged, object: nil)
        
        setupAutoDeleteTimer()
    }
    
    @objc private func maxItemsDidChange(_ notification: Notification) {
        guard let newMax = notification.object as? Int else { return }
        
        if items.count > newMax {
            items = Array(items.prefix(newMax))
            saveToDisk()
        }
    }
    
    private func setupAutoDeleteTimer() {
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.deleteOldItems()
        }
    }
    
    private func deleteOldItems() {
        let days = AppSettings.shared.autoDeleteAfterDays
        
        guard days > 0 else { return }
        
        let cutoffDate = Date().addingTimeInterval(TimeInterval(-Double(days * 86400)))
        let oldCount = items.count
        
        items.removeAll { $0.timestamp < cutoffDate }
        
        if items.count < oldCount {
            saveToDisk()
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        guard pasteboard.changeCount != lastChangeCount else {
            return
        }
        
        lastChangeCount = pasteboard.changeCount
        
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !fileURLs.isEmpty {
            handleFileURLs(fileURLs)
            return
        }
        
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            handleImage(imageData)
            return
        }
        
        guard let text = pasteboard.string(forType: .string) else {
            return
        }
        
        guard !text.isEmpty else {
            return
        }
        
        if isValidURL(text) {
            handleURL(text)
        } else {
            handleText(text)
        }
    }
    
    private func handleText(_ text: String) {
        let newItem = ClipboardItem(text: text)
        addItem(newItem)
    }
    
    private func handleURL(_ urlString: String) {
        let newItem = ClipboardItem(url: urlString)
        addItem(newItem)
    }
    
    private func handleImage(_ imageData: Data) {
        guard let image = NSImage(data: imageData) else {
            return
        }
        
        let newItem = ClipboardItem(image: image)
        addItem(newItem)
    }
    
    private func handleImageFiles(_ imageURLs: [URL]) {
        for imageURL in imageURLs {
            if let image = NSImage(contentsOf: imageURL) {
                let format = imageURL.pathExtension
                let newItem = ClipboardItem(image: image, format: format)
                addItem(newItem)
            }
        }
    }
    
    private func handleFileURLs(_ urls: [URL]) {
        let imageFiles = urls.filter { isImageFile($0) }
        
        if !imageFiles.isEmpty {
            handleImageFiles(imageFiles)
        } else {
            let fileList = urls.map { $0.lastPathComponent }.joined(separator: "\n")
            handleText(fileList)
        }
    }
    
    private func isImageFile(_ url: URL) -> Bool {
        let imageExtensions = [
            "png", "jpg", "jpeg", "gif", "bmp",
            "tiff", "tif", "heic", "heif", "webp",
            "ico", "icns", "svg", "raw", "cr2", "nef"
        ]
        let ext = url.pathExtension.lowercased()
        return imageExtensions.contains(ext)
    }
    
    private func isValidURL(_ string: String) -> Bool {
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            return true
        }
        
        if let url = URL(string: string),
           url.scheme != nil,
           url.host != nil {
            return true
        }
        
        return false
    }
    
    private func addItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        
        checkNearMaxItems()
        
        saveToDisk()
    }
    
    private func checkNearMaxItems() {
        let threshold = Int(Double(maxItems) * 0.9)
        
        if items.count >= threshold && !hasNotifiedNearMax {
            hasNotifiedNearMax = true
            
            if AppSettings.shared.showNotifications {
                showNotification(
                    title: "Clipboard",
                    body: "Your clipboard nearly full (\(items.count) / \(maxItems) items). Consider clearing some to free up space."
                )
            }
            
            if items.count < threshold - 5 {
                hasNotifiedNearMax = false
            }
        }
    }
    
    func copyItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.type {
        case .text, .url:
            if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
            
        case .image:
            if let image = item.image {
                pasteboard.writeObjects([image])
            }
        }
        
        
        lastChangeCount = pasteboard.changeCount
    }
    
    func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveToDisk()
    }
    
    func clearAll() {
        items.removeAll()
        saveToDisk()
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(items) {
            UserDefaults.standard.set(encoded, forKey: "clipboardHistory")
        }
    }
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            return
        }
        
        items = decoded
    }
    
    private func showNotification(title: String, body: String) {
        let notification = UNMutableNotificationContent()
        notification.title = title
        notification.body = body
        notification.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: notification,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
