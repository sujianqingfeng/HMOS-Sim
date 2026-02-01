import AppKit
import Foundation

@MainActor
final class HilogModel: ObservableObject {
    @Published var selectedConnectKey: String?
    @Published var isStreaming = false
    @Published var isPaused = false
    @Published var filterText = ""
    @Published var lastError: String?
    @Published private(set) var lines: [String] = []

    private var process: Process?
    private var stdoutHandle: FileHandle?
    private var stderrHandle: FileHandle?
    private let maxLines = 5_000

    func startStreaming(config: DevEcoToolsConfig) {
        guard let connectKey = selectedConnectKey, !connectKey.isEmpty else {
            lastError = "Select a device target first."
            return
        }

        stopStreaming()
        lastError = nil
        isPaused = false

        let executableURL = URL(fileURLWithPath: config.hdcPath.expandedPath)
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            lastError = ToolConfigError.missingExecutable(executableURL.path).localizedDescription
            return
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["-t", connectKey, "hilog"]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutHandle = stdoutPipe.fileHandleForReading
        self.stdoutHandle = stdoutHandle

        let reader = LineBufferedReader()
        stdoutHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard let self else { return }

            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }

            let newLines = reader.append(data)
            Task { @MainActor in
                guard !self.isPaused else { return }
                self.appendLines(newLines)
            }
        }

        let stderrHandle = stderrPipe.fileHandleForReading
        self.stderrHandle = stderrHandle
        stderrHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard let self else { return }
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            let text = String(data: data, encoding: .utf8) ?? ""
            Task { @MainActor in
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    self.lastError = trimmed
                }
            }
        }

        do {
            try process.run()
        } catch {
            stdoutHandle.readabilityHandler = nil
            stderrHandle.readabilityHandler = nil
            lastError = error.localizedDescription
            return
        }

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.isStreaming = false
            }
        }

        self.process = process
        isStreaming = true
    }

    func stopStreaming() {
        process?.terminate()
        process = nil
        stdoutHandle?.readabilityHandler = nil
        stderrHandle?.readabilityHandler = nil
        stdoutHandle = nil
        stderrHandle = nil
        isStreaming = false
    }

    func clear() {
        lines.removeAll(keepingCapacity: true)
    }

    func copyFilteredToClipboard() {
        let text = filteredLines().joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func filteredLines() -> [String] {
        let filter = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !filter.isEmpty else { return lines }

        return lines.filter { $0.localizedCaseInsensitiveContains(filter) }
    }

    private func appendLines(_ newLines: [String]) {
        guard !newLines.isEmpty else { return }

        lines.append(contentsOf: newLines)
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
    }
}

final class LineBufferedReader: @unchecked Sendable {
    private var buffer = Data()

    func append(_ data: Data) -> [String] {
        buffer.append(data)

        var lines: [String] = []
        while let range = buffer.firstRange(of: Data([0x0A])) { // '\n'
            let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex...range.lowerBound)
            if let line = String(data: lineData, encoding: .utf8) {
                lines.append(line.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return lines
    }
}
