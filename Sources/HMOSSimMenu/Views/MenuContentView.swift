import AppKit
import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let online = appModel.hdcTargets.filter(\.isOnline).count
        let total = appModel.hdcTargets.count

        Text("Instances: \(appModel.instances.count)")
        Text("hdc: \(online)/\(total) online")

        if let err = appModel.lastError {
            Divider()
            Text(err)
                .foregroundStyle(.red)
                .lineLimit(3)
        }

        Divider()

        Button("Refresh Now") { appModel.refreshNow() }
            .keyboardShortcut("r")

        Button("Restart hdc Server") { appModel.restartHdcServer() }

        Divider()

        if appModel.instances.isEmpty {
            Text("No emulator instances found.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(appModel.instances) { instance in
                Menu(instance.name) {
                    Button("Start") { appModel.startEmulator(named: instance.name) }
                    Button("Stop") { appModel.stopEmulator(named: instance.name) }
                }
            }
        }

        Divider()

        Button("Dashboard…") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }

        Button("Hilog…") {
            appModel.autoStartHilogOnOpen = true
            openWindow(id: "logs")
        }
            .keyboardShortcut("l")

        Button("Open Logs (No Auto Start)…") {
            appModel.autoStartHilogOnOpen = false
            openWindow(id: "logs")
        }

        Button("Settings…") {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
