import SwiftUI

struct SettingsView: View {
    @AppStorage(DefaultsKey.emulatorPath) private var emulatorPath: String = DevEcoToolsConfig.loadFromDefaults().emulatorPath
    @AppStorage(DefaultsKey.hdcPath) private var hdcPath: String = DevEcoToolsConfig.loadFromDefaults().hdcPath
    @AppStorage(DefaultsKey.emulatorInstancePath) private var emulatorInstancePath: String = DevEcoToolsConfig.loadFromDefaults().emulatorInstancePath
    @AppStorage(DefaultsKey.emulatorImageRootPath) private var emulatorImageRootPath: String = DevEcoToolsConfig.loadFromDefaults().emulatorImageRootPath
    @AppStorage(DefaultsKey.refreshIntervalSeconds) private var refreshIntervalSeconds: Double = DevEcoToolsConfig.loadFromDefaults().refreshIntervalSeconds

    var body: some View {
        Form {
            Section("DevEco Tools") {
                TextField("Emulator path", text: $emulatorPath)
                    .textFieldStyle(.roundedBorder)
                TextField("hdc path", text: $hdcPath)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Emulator Start Args") {
                TextField("Instance path (-path)", text: $emulatorInstancePath)
                    .textFieldStyle(.roundedBorder)
                TextField("Image root (-imageRoot)", text: $emulatorImageRootPath)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Refresh") {
                HStack {
                    Text("Interval (seconds)")
                    Spacer()
                    TextField("", value: $refreshIntervalSeconds, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                Text("Tip: set 1–3 seconds for responsive status updates.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 620)
    }
}

