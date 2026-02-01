import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var instances: [EmulatorInstance] = []
    @Published private(set) var hdcTargets: [HdcTarget] = []
    @Published private(set) var lastRefresh: Date?
    @Published var lastError: String?
    @Published var autoStartHilogOnOpen = false
    @Published var preferredLogTarget: String?

    var config: DevEcoToolsConfig { DevEcoToolsConfig.loadFromDefaults() }

    private let emulatorService = EmulatorService()
    private let hdcService = HdcService()
    private var refreshTask: Task<Void, Never>?
    private var isMenuOpen = false

    init() {
        DevEcoToolsResolver.bootstrapDefaultsIfNeeded()
        startAutoRefresh()
    }

    func setMenuOpen(_ open: Bool) {
        isMenuOpen = open
    }

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshAll()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.config.refreshIntervalSeconds))
                await self.refreshAll()
            }
        }
    }

    func refreshNow() {
        Task { await refreshAll() }
    }

    func refreshAll() async {
        if isMenuOpen {
            return
        }

        let config = config
        var didChange = false
        var instanceError: Error?
        var targetError: Error?

        do {
            let newInstances = try emulatorService.listInstances(config: config)
            if newInstances != instances {
                instances = newInstances
                didChange = true
            }
        } catch {
            instanceError = error
        }

        do {
            let targets = try hdcService.listTargets(config: config)
            if targets != hdcTargets {
                hdcTargets = targets
                didChange = true
            }
        } catch {
            targetError = error
        }

        let newError = (targetError ?? instanceError)?.localizedDescription
        if newError != lastError {
            lastError = newError
            didChange = true
        }

        if didChange {
            lastRefresh = Date()
        }
    }

    func startEmulator(named name: String) {
        Task {
            do {
                try emulatorService.startInstance(named: name, config: config)
                await refreshAll()
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func stopEmulator(named name: String) {
        Task {
            do {
                try emulatorService.stopInstance(named: name, config: config)
                await refreshAll()
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func restartHdcServer() {
        Task {
            do {
                try hdcService.restartServer(config: config)
                await refreshAll()
            } catch {
                lastError = error.localizedDescription
            }
        }
    }
}
