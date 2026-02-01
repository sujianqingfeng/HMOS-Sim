import Foundation

struct HdcService {
    func listTargets(config: DevEcoToolsConfig) throws -> [HdcTarget] {
        let result = try ProcessRunner.capture(
            executablePath: config.hdcPath,
            arguments: ["list", "targets", "-v"]
        )

        return result.stdout
            .split(whereSeparator: \.isNewline)
            .compactMap { parseTargetLine(String($0)) }
    }

    func restartServer(config: DevEcoToolsConfig) throws {
        _ = try ProcessRunner.capture(
            executablePath: config.hdcPath,
            arguments: ["start", "-r"]
        )
    }

    private func parseTargetLine(_ line: String) -> HdcTarget? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Example:
        // 127.0.0.1:5555        TCP     Offline  localhost
        let parts = trimmed.split(whereSeparator: \.isWhitespace)
        guard parts.count >= 3 else { return nil }

        let connectKey = String(parts[0])
        let transport = String(parts[1])
        let state = String(parts[2])
        let desc = parts.count >= 4 ? parts[3...].joined(separator: " ") : nil

        return HdcTarget(connectKey: connectKey, transport: transport, state: state, description: desc)
    }
}

