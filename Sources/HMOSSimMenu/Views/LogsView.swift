import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var hilog = HilogModel()

    @State private var autoscroll = true

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
                ForEach(appModel.hdcTargets) { target in
                    Text("\(target.connectKey)  (\(target.state))")
                        .tag(Optional(target.connectKey))
                }
            }
            .frame(width: 320)

            Button(hilog.isStreaming ? "Stop" : "Start") {
                if hilog.isStreaming {
                    hilog.stopStreaming()
                } else {
                    hilog.startStreaming(config: appModel.config)
                }
            }
            .keyboardShortcut(.space, modifiers: [])

            Toggle("Pause", isOn: $hilog.isPaused)
                .toggleStyle(.switch)

            Toggle("Autoscroll", isOn: $autoscroll)
                .toggleStyle(.switch)

            TextField("Filter", text: $hilog.filterText)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 180)

            Button("Copy") { hilog.copyFilteredToClipboard() }

            Button("Clear") { hilog.clear() }

            Spacer()

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
}
