import AppKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow
    @State private var instanceFilter = ""
    @State private var targetFilter = ""
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            content
                .frame(maxHeight: .infinity)
            
            // Error
            if let err = appModel.lastError {
                Divider()
                errorView(err)
            }
        }
        .frame(minWidth: 800, minHeight: 480)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    isRefreshing = true
                    appModel.refreshNow()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isRefreshing = false
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .keyboardShortcut("r")
                
                Button {
                    appModel.autoStartHilogOnOpen = true
                    openWindow(id: "logs")
                } label: {
                    Label("Hilog…", systemImage: "waveform")
                }
                .keyboardShortcut("l")
                
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Label("Settings…", systemImage: "gear")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                } else {
                    Button {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } label: {
                        Label("Settings…", systemImage: "gear")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        let online = appModel.hdcTargets.filter(\.isOnline).count
        let total = appModel.hdcTargets.count
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("HMOS Sim")
                    .font(.title2.weight(.semibold))
                Text("\(appModel.instances.count) instances · \(online)/\(total) devices online")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let lastRefresh = appModel.lastRefresh {
                Text("Updated \(lastRefresh.formatted(date: .omitted, time: .standard))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Content
    private var content: some View {
        HStack(spacing: 16) {
            // Instances Panel
            instancesPanel
            
            // Targets Panel
            targetsPanel
        }
        .padding()
    }

    // MARK: - Instances Panel
    private var instancesPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Emulators", systemImage: "macwindow")
                    .font(.headline)
                Spacer()
                Text("\(filteredInstances.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Search
            SimpleSearchField(text: $instanceFilter, placeholder: "Filter...")
                .padding()
            
            // List
            List(filteredInstances) { instance in
                InstanceRow(instance: instance, appModel: appModel)
                    .listRowSeparator(.visible)
            }
            .listStyle(InsetListStyle())
            .overlay {
                if filteredInstances.isEmpty {
                    SimpleEmptyState(
                        title: instanceFilter.isEmpty ? "No instances" : "No matches",
                        systemImage: instanceFilter.isEmpty ? "shippingbox" : "magnifyingglass"
                    )
                }
            }
        }
        .simpleCard()
    }

    // MARK: - Targets Panel
    private var targetsPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("HDC Targets", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline)
                Spacer()
                Text("\(filteredTargets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Search
            SimpleSearchField(text: $targetFilter, placeholder: "Filter...")
                .padding()
            
            // List
            List(filteredTargets) { target in
                TargetRow(target: target, appModel: appModel, openWindow: openWindow)
                    .listRowSeparator(.visible)
            }
            .listStyle(InsetListStyle())
            .overlay {
                if filteredTargets.isEmpty {
                    SimpleEmptyState(
                        title: targetFilter.isEmpty ? "No targets" : "No matches",
                        systemImage: targetFilter.isEmpty ? "antenna.radiowaves.left.and.right" : "magnifyingglass"
                    )
                }
            }
        }
        .simpleCard()
    }

    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(error)
                .font(.subheadline)
                .lineLimit(2)
            Spacer()
            Button {
                appModel.lastError = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .foregroundStyle(.red)
        .padding()
    }

    // MARK: - Filter Logic
    private var filteredInstances: [EmulatorInstance] {
        let q = instanceFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return appModel.instances }
        return appModel.instances.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    private var filteredTargets: [HdcTarget] {
        let sorted = appModel.hdcTargets.sorted { lhs, rhs in
            if lhs.isOnline != rhs.isOnline { return lhs.isOnline && !rhs.isOnline }
            return lhs.connectKey < rhs.connectKey
        }
        let q = targetFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return sorted }
        return sorted.filter { 
            $0.connectKey.localizedCaseInsensitiveContains(q) || 
            $0.state.localizedCaseInsensitiveContains(q) 
        }
    }
}

// MARK: - Instance Row
private struct InstanceRow: View {
    let instance: EmulatorInstance
    let appModel: AppModel
    
    var body: some View {
        HStack {
            Text(instance.name)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 8) {
                Button {
                    appModel.startEmulator(named: instance.name)
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.green)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    appModel.stopEmulator(named: instance.name)
                } label: {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .contextMenu {
            Button("Start") { appModel.startEmulator(named: instance.name) }
            Button("Stop") { appModel.stopEmulator(named: instance.name) }
            Divider()
            Button("Copy Name") { 
                NSPasteboard.general.setString(instance.name, forType: .string) 
            }
        }
    }
}

// MARK: - Target Row
private struct TargetRow: View {
    let target: HdcTarget
    let appModel: AppModel
    let openWindow: OpenWindowAction
    
    var body: some View {
        HStack(spacing: 12) {
            StatusBadge(isOnline: target.isOnline)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(target.connectKey)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                Text("\(target.transport) · \(target.state)")
                    .font(.caption)
                    .foregroundStyle(target.isOnline ? .green : .secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    NSPasteboard.general.setString(target.connectKey, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(PlainButtonStyle())
                .help("Copy")
                
                Button {
                    appModel.preferredLogTarget = target.connectKey
                    appModel.autoStartHilogOnOpen = true
                    openWindow(id: "logs")
                } label: {
                    Image(systemName: "waveform")
                }
                .buttonStyle(PlainButtonStyle())
                .help("Logs")
                .disabled(!target.isOnline)
            }
        }
        .contextMenu {
            Button("Copy key") { 
                NSPasteboard.general.setString(target.connectKey, forType: .string) 
            }
            if target.isOnline {
                Button("Open logs") {
                    appModel.preferredLogTarget = target.connectKey
                    appModel.autoStartHilogOnOpen = true
                    openWindow(id: "logs")
                }
            }
        }
    }
}
