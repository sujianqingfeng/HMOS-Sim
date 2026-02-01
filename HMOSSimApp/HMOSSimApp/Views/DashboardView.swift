import AppKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow
    @State private var instanceFilter = ""
    @State private var targetFilter = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            if let err = appModel.lastError {
                Divider()
                Text(err)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
        }
        .frame(minWidth: 880, minHeight: 520)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    appModel.refreshNow()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                    .keyboardShortcut("r")
                Button {
                    appModel.autoStartHilogOnOpen = true
                    openWindow(id: "logs")
                } label: {
                    Label("Hilog…", systemImage: "waveform.path.ecg")
                }
                    .keyboardShortcut("l")
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Label("Settings…", systemImage: "gearshape")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                } else {
                    Button {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } label: {
                        Label("Settings…", systemImage: "gearshape")
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HMOS Sim")
                    .font(.title2.weight(.semibold))
                let online = appModel.hdcTargets.filter(\.isOnline).count
                let total = appModel.hdcTargets.count
                Text("Instances: \(appModel.instances.count)  ·  hdc: \(online)/\(total) online")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let lastRefresh = appModel.lastRefresh {
                Text("Updated \(lastRefresh.formatted(date: .omitted, time: .standard))")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    private var content: some View {
        HStack(spacing: 12) {
            GroupBox("Emulator Instances") {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "macwindow.and.cursorarrow")
                            .foregroundStyle(.secondary)
                        TextField("Filter instances", text: $instanceFilter)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    List(filteredInstances) { instance in
                        HStack(spacing: 10) {
                            Text(instance.name)
                                .lineLimit(1)
                            Spacer()

                            Button {
                                appModel.startEmulator(named: instance.name)
                            } label: {
                                Image(systemName: "play.fill")
                            }
                            .help("Start \(instance.name)")

                            Button {
                                appModel.stopEmulator(named: instance.name)
                            } label: {
                                Image(systemName: "stop.fill")
                            }
                            .help("Stop \(instance.name)")
                        }
                        .contextMenu {
                            Button("Start") { appModel.startEmulator(named: instance.name) }
                            Button("Stop") { appModel.stopEmulator(named: instance.name) }
                            Divider()
                            Button("Copy Name") { NSPasteboard.general.setString(instance.name, forType: .string) }
                        }
                    }
                }
                .overlay {
                    if filteredInstances.isEmpty {
                        EmptyStateView(
                            title: "No instances found",
                            systemImage: instanceFilter.isEmpty ? "shippingbox" : "magnifyingglass"
                        )
                    }
                }
            }

            GroupBox("hdc Targets") {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.secondary)
                        TextField("Filter targets", text: $targetFilter)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    List(filteredTargets) { target in
                        HStack(spacing: 10) {
                            StatusDot(isOn: target.isOnline)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(target.connectKey)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                Text("\(target.transport) · \(target.state)")
                                    .foregroundStyle(target.isOnline ? .green : .secondary)
                                    .font(.caption)
                            }

                            Spacer()

                            Button {
                                NSPasteboard.general.setString(target.connectKey, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .help("Copy connect key")

                            Button {
                                appModel.preferredLogTarget = target.connectKey
                                appModel.autoStartHilogOnOpen = true
                                openWindow(id: "logs")
                            } label: {
                                Image(systemName: "waveform.path.ecg")
                            }
                            .help("Open hilog")
                            .disabled(!target.isOnline)
                        }
                        .contextMenu {
                            Button("Copy connect key") { NSPasteboard.general.setString(target.connectKey, forType: .string) }
                            if target.isOnline {
                                Button("Open hilog") {
                                    appModel.preferredLogTarget = target.connectKey
                                    appModel.autoStartHilogOnOpen = true
                                    openWindow(id: "logs")
                                }
                            }
                        }
                    }
                }
                .overlay {
                    if filteredTargets.isEmpty {
                        EmptyStateView(
                            title: "No hdc targets",
                            systemImage: targetFilter.isEmpty ? "antenna.radiowaves.left.and.right" : "magnifyingglass"
                        )
                    }
                }
            }
        }
        .padding(16)
    }

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
        return sorted.filter { $0.connectKey.localizedCaseInsensitiveContains(q) || $0.state.localizedCaseInsensitiveContains(q) }
    }
}

private struct EmptyStateView: View {
    var title: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)
            Text(title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

private struct StatusDot: View {
    var isOn: Bool

    var body: some View {
        Circle()
            .fill(isOn ? Color.green : Color.secondary.opacity(0.55))
            .frame(width: 9, height: 9)
            .overlay {
                Circle()
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            }
            .accessibilityLabel(isOn ? "Online" : "Offline")
    }
}
