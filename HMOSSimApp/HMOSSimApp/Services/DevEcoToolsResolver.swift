import Foundation

enum DevEcoToolsResolver {
    static func bootstrapDefaultsIfNeeded() {
        let defaults = UserDefaults.standard

        let emulatorPath = defaults.string(forKey: DefaultsKey.emulatorPath)
        if emulatorPath == nil || !FileManager.default.isExecutableFile(atPath: emulatorPath!.expandedPath) {
            if let detected = detectEmulatorPath() {
                defaults.set(detected, forKey: DefaultsKey.emulatorPath)
            }
        }

        let hdcPath = defaults.string(forKey: DefaultsKey.hdcPath)
        if hdcPath == nil || !FileManager.default.isExecutableFile(atPath: hdcPath!.expandedPath) {
            if let detected = detectHdcPath() {
                defaults.set(detected, forKey: DefaultsKey.hdcPath)
            }
        }

        let instancePath = defaults.string(forKey: DefaultsKey.emulatorInstancePath)
        if instancePath == nil {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let candidate = "\(home)/.Huawei/Emulator/deployed"
            if FileManager.default.fileExists(atPath: candidate) {
                defaults.set(candidate, forKey: DefaultsKey.emulatorInstancePath)
            }
        }

        let imageRootPath = defaults.string(forKey: DefaultsKey.emulatorImageRootPath)
        if imageRootPath == nil {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let candidate = "\(home)/Library/Huawei/Sdk"
            if FileManager.default.fileExists(atPath: candidate) {
                defaults.set(candidate, forKey: DefaultsKey.emulatorImageRootPath)
            }
        }

        if defaults.object(forKey: DefaultsKey.refreshIntervalSeconds) == nil {
            defaults.set(2.0, forKey: DefaultsKey.refreshIntervalSeconds)
        }
    }

    static func detectEmulatorPath() -> String? {
        guard let app = detectDevEcoStudioApp() else { return nil }
        let path = app.appendingPathComponent("Contents/tools/emulator/Emulator").path
        return FileManager.default.isExecutableFile(atPath: path) ? path : nil
    }

    static func detectHdcPath() -> String? {
        guard let app = detectDevEcoStudioApp() else { return nil }
        let path = app.appendingPathComponent("Contents/sdk/default/openharmony/toolchains/hdc").path
        return FileManager.default.isExecutableFile(atPath: path) ? path : nil
    }

    private static func detectDevEcoStudioApp() -> URL? {
        let fm = FileManager.default
        let applications = URL(fileURLWithPath: "/Applications", isDirectory: true)

        // Prefer the common fixed name.
        let common = applications.appendingPathComponent("DevEco-Studio.app")
        if fm.fileExists(atPath: common.path) {
            return common
        }

        // Fallback: find any DevEco*.app in /Applications that contains the expected tool layout.
        guard let entries = try? fm.contentsOfDirectory(at: applications, includingPropertiesForKeys: nil) else {
            return nil
        }

        let candidates = entries
            .filter { $0.pathExtension == "app" }
            .filter { $0.lastPathComponent.localizedCaseInsensitiveContains("deveco") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }

        for app in candidates {
            let emulator = app.appendingPathComponent("Contents/tools/emulator/Emulator").path
            let hdc = app.appendingPathComponent("Contents/sdk/default/openharmony/toolchains/hdc").path
            if fm.isExecutableFile(atPath: emulator) && fm.isExecutableFile(atPath: hdc) {
                return app
            }
        }

        return nil
    }
}

