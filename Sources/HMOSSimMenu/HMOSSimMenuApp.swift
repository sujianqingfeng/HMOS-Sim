import SwiftUI

@main
struct HMOSSimMenuApp: App {
    @StateObject private var appModel: AppModel

    init() {
        _appModel = StateObject(wrappedValue: AppModel())
    }

    var body: some Scene {
        WindowGroup("Dashboard") {
            DashboardView()
                .environmentObject(appModel)
        }

        MenuBarExtra {
            MenuContentView()
                .environmentObject(appModel)
        } label: {
            Label("HMOS Sim", systemImage: "cpu")
        }

        WindowGroup("Logs", id: "logs") {
            LogsView()
                .environmentObject(appModel)
        }

        Settings {
            SettingsView()
                .environmentObject(appModel)
        }
    }
}
