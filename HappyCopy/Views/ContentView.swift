//
//  ContentView.swift
//  HappyCopy
//
//  Created by Nguyen Huy Hoang on 3/11/25.
//  Enhanced with Image Preview Feature
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @State private var hoveredItemID: UUID?
    @State private var searchText = ""
    @State private var selectedFilter: ClipboardItemType? = nil
    
    var filteredItems: [ClipboardItem] {
        var items = monitor.items
        
        if let filter = selectedFilter {
            items = items.filter { $0.type == filter }
        }
        
        if !searchText.isEmpty {
            items = items.filter { item in
                switch item.type {
                case .text, .url:
                    return item.text?.localizedCaseInsensitiveContains(searchText) ?? false
                case .image:
                    return item.preview.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        return items
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            searchFilterBar
            
            Divider()
            
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                listView
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text(AppInfo.name)
                .font(.headline)
            
            SettingsLink {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
            
            Spacer()
            
            Text(countText)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(8)
            
            Button(action: deleteItems) {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(deleteTooltip)
        }
        .padding(12)
    }
    
    private var countText: String {
        if selectedFilter == nil && searchText.isEmpty {
            return "\(monitor.items.count)"
        } else {
            return "\(filteredItems.count) / \(monitor.items.count)"
        }
    }
    
    private var deleteTooltip: String {
        if selectedFilter == nil && searchText.isEmpty {
            return String(localized: "Clear all")
        } else {
            return String(localized: "Delete \(filteredItems.count) items")
        }
    }
    
    private var searchFilterBar: some View {
        HStack(spacing: 8) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            
            // Filter dropdown
            Menu {
                Button(action: { selectedFilter = nil }) {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                        Text("All")
                    }
                }
                
                Divider()
                
                Button(action: { selectedFilter = .text }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Text")
                    }
                }
                
                Button(action: { selectedFilter = .image }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Image")
                    }
                }
                
                Button(action: { selectedFilter = .url }) {
                    HStack {
                        Image(systemName: "link")
                        Text("URL")
                    }
                }
            } label: {
                HStack() {
                    Text(filterLabel)
                        .font(.caption2)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(width: 84)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Filter by type")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
    }

    private var filterLabel: String {
        switch selectedFilter {
        case .none: return String(localized: "All")
        case .text: return String(localized: "Text")
        case .image: return String(localized: "Image")
        case .url: return String(localized: "URL")
        }
    }

    private func deleteItems() {
        if selectedFilter == nil && searchText.isEmpty {
            monitor.clearAll()
        } else {
            let itemsToDelete = filteredItems
            
            for item in itemsToDelete {
                monitor.deleteItem(item)
            }
            
            searchText = ""
            selectedFilter = nil
        }
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredItems) { item in
                    ClipboardItemRow(
                        item: item,
                        isHovered: hoveredItemID == item.id,
                        onCopy: { monitor.copyItem(item) },
                        onDelete: { monitor.deleteItem(item) }
                    )
                    .onHover { isHovered in
                        hoveredItemID = isHovered ? item.id : nil
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle.text.clipboard")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No clipboard history")
                .font(.headline)
            
            Text("Copy something to get started")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Clipboard Item Row
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isHovered: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    // State để quản lý việc hiển thị preview window
    @State private var showImagePreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch item.type {
            case .text:
                textContent
                
            case .url:
                urlContent
                
            case .image:
                imageContent
            }
            
            HStack(alignment: .center) {
                Image(systemName: typeIcon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(item.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isHovered {
                    if item.type == .image {
                        Button(action: { showImagePreview = true }) {
                            Image(systemName: "light.panel")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Preview image")
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
            }
            
            Divider()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
        .popover(isPresented: $showImagePreview, arrowEdge: .trailing) {
            if let image = item.image {
                ImagePreview(image: image, preview: item.preview)
            }
        }
    }
    
    private var typeIcon: String {
        switch item.type {
        case .text: return "doc.text"
        case .url: return "link"
        case .image: return "photo"
        }
    }
    
    private var textContent: some View {
        Text(item.text ?? "")
            .font(.body)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var urlContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            ClickableURL(urlString: item.text ?? "")
            
            Text(item.preview)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
    
    private var imageContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let image = item.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .cornerRadius(4)
            }
            
            Text(item.preview)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Image Preview
struct ImagePreview: View {
    let image: NSImage
    let preview: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Image Preview")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Ảnh preview với scroll
            ScrollView([.horizontal, .vertical]) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 800, maxHeight: 600)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
            
            Text(preview)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Clickable URL
struct ClickableURL: View {
    let urlString: String
    @State private var isHovered: Bool = false
    
    var body: some View {
        Text(urlString)
            .font(.body)
            .lineLimit(3)
            .foregroundStyle(Color(NSColor.linkColor))
            .underline(isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                openURL()
            }
            .cursor(NSCursor.pointingHand)
            .help("Click to open in browser")
    }
    
    private func openURL() {
        guard let url = URL(string: urlString) else {
            return
        }
        
        NSWorkspace.shared.open(url)
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(monitor: ClipboardMonitor())
            .frame(width: 350, height: 500)
    }
}
