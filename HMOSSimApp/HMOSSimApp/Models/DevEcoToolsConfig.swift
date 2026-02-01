import Foundation

struct DevEcoToolsConfig: Equatable {
    var emulatorPath: String
    var hdcPath: String
    var emulatorInstancePath: String
    var emulatorImageRootPath: String
    var refreshIntervalSeconds: Double

    static func defaultPaths() -> (emulatorPath: String, hdcPath: String, emulatorInstancePath: String, emulatorImageRootPath: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return (
            emulatorPath: "/Applications/DevEco-Studio.app/Contents/tools/emulator/Emulator",
            hdcPath: "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc",
            emulatorInstancePath: "\(home)/.Huawei/Emulator/deployed",
            emulatorImageRootPath: "\(home)/Library/Huawei/Sdk"
        )
    }

    static func loadFromDefaults() -> Self {
        let defaults = UserDefaults.standard
        let defaultsPaths = defaultPaths()

        let emulatorPath = defaults.string(forKey: DefaultsKey.emulatorPath) ?? defaultsPaths.emulatorPath
        let hdcPath = defaults.string(forKey: DefaultsKey.hdcPath) ?? defaultsPaths.hdcPath
        let emulatorInstancePath = defaults.string(forKey: DefaultsKey.emulatorInstancePath) ?? defaultsPaths.emulatorInstancePath
        let emulatorImageRootPath = defaults.string(forKey: DefaultsKey.emulatorImageRootPath) ?? defaultsPaths.emulatorImageRootPath
        let refreshIntervalSeconds: Double = {
            if let number = defaults.object(forKey: DefaultsKey.refreshIntervalSeconds) as? NSNumber {
                return max(0.5, number.doubleValue)
            }
            return 2.0
        }()

        return Self(
            emulatorPath: emulatorPath,
            hdcPath: hdcPath,
            emulatorInstancePath: emulatorInstancePath,
            emulatorImageRootPath: emulatorImageRootPath,
            refreshIntervalSeconds: refreshIntervalSeconds
        )
    }
}

enum ToolConfigError: LocalizedError {
    case missingExecutable(String)
    case missingRequiredSetting(String)

    var errorDescription: String? {
        switch self {
        case .missingExecutable(let path):
            return "Missing executable: \(path)"
        case .missingRequiredSetting(let setting):
            return "Missing required setting: \(setting)"
        }
    }
}

extension String {
    var expandedPath: String { (self as NSString).expandingTildeInPath }
}
