import SwiftUI

@main
struct HMOSSimApp: App {
    @StateObject private var appModel: AppModel

    init() {
        _appModel = StateObject(wrappedValue: AppModel())
    }

    var body: some Scene {
        WindowGroup("Dashboard", id: "dashboard") {
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
