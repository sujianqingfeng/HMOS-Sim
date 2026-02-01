import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var hilog = HilogModel()

    @State private var autoscroll = true
    @State private var showOnlyOnlineTargets = true

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            logBody
        }
        .onAppear {
            if let preferred = appModel.preferredLogTarget, !preferred.isEmpty {
                hilog.selectedConnectKey = preferred
            }

            if hilog.selectedConnectKey == nil {
                hilog.selectedConnectKey = appModel.hdcTargets.first(where: \.isOnline)?.connectKey
                    ?? appModel.hdcTargets.first?.connectKey
            }

            if appModel.autoStartHilogOnOpen {
                appModel.autoStartHilogOnOpen = false
                if !hilog.isStreaming {
                    hilog.startStreaming(config: appModel.config)
                }
            }
        }
        .onChange(of: hilog.selectedConnectKey) { _ in
            guard hilog.isStreaming else { return }
            hilog.clear()
            hilog.startStreaming(config: appModel.config)
        }
        .onDisappear {
            hilog.stopStreaming()
        }
        .frame(minWidth: 900, minHeight: 560)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Picker("Target", selection: $hilog.selectedConnectKey) {
                ForEach(visibleTargets) { target in
                    Text("\(target.connectKey)  (\(target.state))")
                        .tag(Optional(target.connectKey))
                }
            }
            .frame(width: 320)

            Button {
                if hilog.isStreaming {
                    hilog.stopStreaming()
                } else {
                    hilog.startStreaming(config: appModel.config)
                }
            } label: {
                Label(hilog.isStreaming ? "Stop" : "Start", systemImage: hilog.isStreaming ? "stop.fill" : "play.fill")
            }
            .keyboardShortcut(.space, modifiers: [])
            .disabled(selectedTarget?.isOnline == false)
            .help(selectedTarget?.isOnline == false ? "Selected target is offline" : (hilog.isStreaming ? "Stop streaming" : "Start streaming"))

            Toggle("Pause", isOn: $hilog.isPaused)
                .toggleStyle(.switch)
                .disabled(!hilog.isStreaming)

            Toggle("Autoscroll", isOn: $autoscroll)
                .toggleStyle(.switch)

            TextField("Filter", text: $hilog.filterText)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 180)

            Button {
                hilog.copyFilteredToClipboard()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .help("Copy filtered logs to clipboard")

            Button {
                hilog.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }

            Spacer()

            Toggle("Online only", isOn: $showOnlyOnlineTargets)
                .toggleStyle(.switch)
                .help("Hide offline targets in picker")

            Text("\(hilog.filteredLines().count) lines")
                .foregroundStyle(.secondary)

            if let err = hilog.lastError {
                Text(err)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
        .padding(12)
    }

    private var logBody: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    let filteredLines = hilog.filteredLines()
                    ForEach(Array(filteredLines.enumerated()), id: \.offset) { idx, line in
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .id(idx)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(12)
            }
            .onChange(of: hilog.filterText) { _ in
                // Trigger scroll recalculation when filter changes.
                guard autoscroll else { return }
                let filtered = hilog.filteredLines()
                if let last = filtered.indices.last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
            .onChange(of: hilog.filteredLines().count) { newCount in
                guard autoscroll, newCount > 0 else { return }
                proxy.scrollTo(newCount - 1, anchor: .bottom)
            }
        }
        .background(.background)
    }

    private var selectedTarget: HdcTarget? {
        guard let key = hilog.selectedConnectKey else { return nil }
        return appModel.hdcTargets.first(where: { $0.connectKey == key })
    }

    private var visibleTargets: [HdcTarget] {
        let sorted = appModel.hdcTargets.sorted { lhs, rhs in
            if lhs.isOnline != rhs.isOnline { return lhs.isOnline && !rhs.isOnline }
            return lhs.connectKey < rhs.connectKey
        }
        return showOnlyOnlineTargets ? sorted.filter(\.isOnline) : sorted
    }
}
