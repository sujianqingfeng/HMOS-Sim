import Foundation

struct DevEcoToolsConfig: Equatable {
    var emulatorPath: String
    var hdcPath: String
    var emulatorInstancePath: String
    var emulatorImageRootPath: String
    var refreshIntervalSeconds: Double

    static func loadFromDefaults() -> Self {
        let defaults = UserDefaults.standard

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let defaultEmulator = "/Applications/DevEco-Studio.app/Contents/tools/emulator/Emulator"
        let defaultHdc = "/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
        let defaultInstancePath = "\(home)/.Huawei/Emulator/deployed"
        let defaultImageRoot = "\(home)/Library/Huawei/Sdk"

        let emulatorPath = defaults.string(forKey: DefaultsKey.emulatorPath) ?? defaultEmulator
        let hdcPath = defaults.string(forKey: DefaultsKey.hdcPath) ?? defaultHdc
        let emulatorInstancePath = defaults.string(forKey: DefaultsKey.emulatorInstancePath) ?? defaultInstancePath
        let emulatorImageRootPath = defaults.string(forKey: DefaultsKey.emulatorImageRootPath) ?? defaultImageRoot
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
