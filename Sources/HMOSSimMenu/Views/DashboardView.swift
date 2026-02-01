import AppKit
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow

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
                Button("Refresh") { appModel.refreshNow() }
                    .keyboardShortcut("r")
                Button("Hilog…") {
                    appModel.autoStartHilogOnOpen = true
                    openWindow(id: "logs")
                }
                    .keyboardShortcut("l")
                Button("Settings…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HMOS Sim Dashboard")
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
                List(appModel.instances) { instance in
                    HStack {
                        Text(instance.name)
                        Spacer()
                        Button("Start") { appModel.startEmulator(named: instance.name) }
                        Button("Stop") { appModel.stopEmulator(named: instance.name) }
                    }
                }
                .overlay {
                    if appModel.instances.isEmpty {
                        EmptyStateView(
                            title: "No instances found",
                            systemImage: "shippingbox"
                        )
                    }
                }
            }

            GroupBox("hdc Targets") {
                List(appModel.hdcTargets) { target in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.connectKey)
                                .font(.system(.body, design: .monospaced))
                            Text("\(target.transport) · \(target.state)")
                                .foregroundStyle(target.isOnline ? .green : .secondary)
                                .font(.caption)
                        }
                        Spacer()
                        Button("Hilog") {
                            appModel.preferredLogTarget = target.connectKey
                            appModel.autoStartHilogOnOpen = true
                            openWindow(id: "logs")
                        }
                        .disabled(!target.isOnline)
                    }
                }
                .overlay {
                    if appModel.hdcTargets.isEmpty {
                        EmptyStateView(
                            title: "No hdc targets",
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                    }
                }
            }
        }
        .padding(16)
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
