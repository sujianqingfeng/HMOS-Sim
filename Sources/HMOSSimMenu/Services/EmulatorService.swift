import Foundation

@MainActor
final class EmulatorService {
    private var runningProcesses: [String: Process] = [:]

    func listInstances(config: DevEcoToolsConfig) throws -> [EmulatorInstance] {
        let result = try ProcessRunner.capture(
            executablePath: config.emulatorPath,
            arguments: ["-list"]
        )

        return result.stdout
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { EmulatorInstance(name: $0) }
    }

    func startInstance(named name: String, config: DevEcoToolsConfig) throws {
        if let existing = runningProcesses[name], existing.isRunning {
            return
        }

        let instancePath = config.emulatorInstancePath.expandedPath
        let imageRoot = config.emulatorImageRootPath.expandedPath

        guard !instancePath.isEmpty else {
            throw ToolConfigError.missingRequiredSetting("Emulator instance path (-path)")
        }
        guard !imageRoot.isEmpty else {
            throw ToolConfigError.missingRequiredSetting("Emulator image root (-imageRoot)")
        }

        // Keep the Process alive; some emulator builds stay attached to the parent.
        let process = try ProcessRunner.spawn(
            executablePath: config.emulatorPath,
            arguments: ["-hvd", name, "-path", instancePath, "-imageRoot", imageRoot]
        )
        runningProcesses[name] = process
    }

    func stopInstance(named name: String, config: DevEcoToolsConfig) throws {
        _ = try ProcessRunner.capture(
            executablePath: config.emulatorPath,
            arguments: ["-stop", name]
        )

        if let process = runningProcesses.removeValue(forKey: name) {
            if process.isRunning {
                process.terminate()
            }
        }
    }

    func collectLogs(
        instanceName name: String,
        outputDirectory: String,
        zipName: String,
        config: DevEcoToolsConfig
    ) throws {
        _ = try ProcessRunner.capture(
            executablePath: config.emulatorPath,
            arguments: ["-logZip", zipName, "-logPath", outputDirectory.expandedPath]
        )
    }
}
