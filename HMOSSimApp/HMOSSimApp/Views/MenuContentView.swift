import AppKit
import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 8) {
            // Stats Header
            let online = appModel.hdcTargets.filter(\.isOnline).count
            let total = appModel.hdcTargets.count
            
            VStack(spacing: 4) {
                Text("HMOS Sim")
                    .font(.headline)
                Text("\(appModel.instances.count) emulators · \(online)/\(total) online")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Actions
            Button("Refresh Now") { appModel.refreshNow() }
                .keyboardShortcut("r")
            
            Button("Restart HDC Server") { appModel.restartHdcServer() }
            
            Divider()
            
            // Instances
            if appModel.instances.isEmpty {
                Text("No emulator instances")
                    .font(.caption)
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
            
            // Navigation
            Button("Dashboard…") { openWindow(id: "dashboard") }
                .keyboardShortcut("d")
            
            Button("Hilog…") {
                appModel.autoStartHilogOnOpen = true
                openWindow(id: "logs")
            }
            .keyboardShortcut("l")
            
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("Settings…")
                }
                .keyboardShortcut(",", modifiers: .command)
            } else {
                Button("Settings…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            
            if let err = appModel.lastError {
                Divider()
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }
            
            Divider()
            
            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(.vertical, 12)
        .frame(width: 240)
        .onAppear { appModel.setMenuOpen(true) }
        .onDisappear {
            appModel.setMenuOpen(false)
            appModel.refreshNow()
        }
    }
}
