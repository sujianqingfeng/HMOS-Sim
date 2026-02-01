import Foundation

struct ProcessResult: Sendable {
    var exitCode: Int32
    var stdout: String
    var stderr: String
}

enum ProcessRunnerError: LocalizedError {
    case failedToStart(String)
    case nonZeroExit(ProcessResult)

    var errorDescription: String? {
        switch self {
        case .failedToStart(let message):
            return "Failed to start process: \(message)"
        case .nonZeroExit(let result):
            let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return stderr.isEmpty ? "Process failed with exit code \(result.exitCode)" : stderr
        }
    }
}

enum ProcessRunner {
    static func capture(
        executablePath: String,
        arguments: [String]
    ) throws -> ProcessResult {
        let executableURL = URL(fileURLWithPath: executablePath.expandedPath)
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw ToolConfigError.missingExecutable(executableURL.path)
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw ProcessRunnerError.failedToStart(error.localizedDescription)
        }

        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let result = ProcessResult(
            exitCode: process.terminationStatus,
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? ""
        )

        if result.exitCode != 0 {
            throw ProcessRunnerError.nonZeroExit(result)
        }

        return result
    }

    static func spawn(
        executablePath: String,
        arguments: [String]
    ) throws -> Process {
        let executableURL = URL(fileURLWithPath: executablePath.expandedPath)
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw ToolConfigError.missingExecutable(executableURL.path)
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        do {
            try process.run()
        } catch {
            throw ProcessRunnerError.failedToStart(error.localizedDescription)
        }

        return process
    }
}

