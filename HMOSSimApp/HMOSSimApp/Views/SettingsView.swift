import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage(DefaultsKey.emulatorPath) private var emulatorPath: String = DevEcoToolsConfig.loadFromDefaults().emulatorPath
    @AppStorage(DefaultsKey.hdcPath) private var hdcPath: String = DevEcoToolsConfig.loadFromDefaults().hdcPath
    @AppStorage(DefaultsKey.emulatorInstancePath) private var emulatorInstancePath: String = DevEcoToolsConfig.loadFromDefaults().emulatorInstancePath
    @AppStorage(DefaultsKey.emulatorImageRootPath) private var emulatorImageRootPath: String = DevEcoToolsConfig.loadFromDefaults().emulatorImageRootPath
    @AppStorage(DefaultsKey.refreshIntervalSeconds) private var refreshIntervalSeconds: Double = DevEcoToolsConfig.loadFromDefaults().refreshIntervalSeconds

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Settings")
                    .font(.title2.weight(.semibold))
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // DevEco Tools Section
                    sectionHeader("DevEco Tools", icon: "hammer")
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PathSettingRow(
                            title: "Emulator Executable",
                            placeholder: "/Applications/DevEco-Studio.app/Contents/tools/emulator",
                            path: $emulatorPath,
                            isFile: true
                        )
                        
                        PathSettingRow(
                            title: "HDC Executable",
                            placeholder: "/Applications/DevEco-Studio.app/Contents/tools/hdc",
                            path: $hdcPath,
                            isFile: true
                        )
                    }
                    
                    Divider()
                    
                    // Emulator Arguments Section
                    sectionHeader("Emulator Arguments", icon: "slider.horizontal.3")
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PathSettingRow(
                            title: "Instance Path (-path)",
                            placeholder: "~/Library/HarmonyOS/emulator/instances",
                            path: $emulatorInstancePath,
                            isFile: false
                        )
                        
                        PathSettingRow(
                            title: "Image Root (-imageRoot)",
                            placeholder: "~/Library/HarmonyOS/emulator/images",
                            path: $emulatorImageRootPath,
                            isFile: false
                        )
                    }
                    
                    Divider()
                    
                    // Refresh Section
                    sectionHeader("Auto Refresh", icon: "arrow.clockwise")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Refresh Interval")
                                .frame(width: 120, alignment: .leading)
                            
                            HStack(spacing: 4) {
                                Slider(value: $refreshIntervalSeconds, in: 1...10, step: 1)
                                    .frame(width: 150)
                                
                                Text("\(Int(refreshIntervalSeconds))s")
                                    .frame(width: 40)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        
                        Text("How often to check emulator and device status")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 520)
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
        }
    }
    
    private func resetToDefaults() {
        let defaults = DevEcoToolsConfig.defaultPaths()
        emulatorPath = defaults.emulatorPath
        hdcPath = defaults.hdcPath
        emulatorInstancePath = defaults.emulatorInstancePath
        emulatorImageRootPath = defaults.emulatorImageRootPath
        refreshIntervalSeconds = 3.0
    }
}

// MARK: - Path Setting Row
struct PathSettingRow: View {
    let title: String
    let placeholder: String
    @Binding var path: String
    let isFile: Bool
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
            
            HStack(spacing: 8) {
                TextField(placeholder, text: $path)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                
                Button {
                    browseForPath()
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .help("Browse...")
                
                if !path.isEmpty {
                    Button {
                        path = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .transition(.scale)
                }
            }
            
            if !path.isEmpty {
                HStack(spacing: 4) {
                    let exists = FileManager.default.fileExists(atPath: path.expandingTilde())
                    Image(systemName: exists ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(exists ? Color.green : Color.orange)
                        .font(.caption)
                    Text(exists ? "Path exists" : "Path not found")
                        .font(.caption)
                        .foregroundStyle(exists ? Color.secondary : Color.orange)
                }
            }
        }
    }
    
    private func browseForPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = isFile
        panel.canChooseDirectories = !isFile
        panel.allowsMultipleSelection = false
        panel.prompt = isFile ? "Select" : "Choose Folder"
        panel.message = isFile ? "Select the executable file" : "Select the folder"
        
        // Set initial directory if current path exists
        if !path.isEmpty {
            let expandedPath = path.expandingTilde()
            if FileManager.default.fileExists(atPath: expandedPath) {
                panel.directoryURL = URL(fileURLWithPath: expandedPath).deletingLastPathComponent()
            }
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                path = url.path
            }
        }
    }
}

// MARK: - String Extension
extension String {
    func expandingTilde() -> String {
        return NSString(string: self).expandingTildeInPath
    }
}
