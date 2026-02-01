import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var hilog = HilogModel()

    @State private var autoscroll = true
    @State private var showOnlyOnlineTargets = true
    @State private var lineWrap = false

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
        .frame(minWidth: 900, minHeight: 600)
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 8) {
            // Top Row: Target & Main Controls
            HStack(spacing: 8) {
                // Target Selector
                HStack(spacing: 4) {
                    Circle()
                        .fill(selectedTarget?.isOnline == true ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    
                    Picker("", selection: $hilog.selectedConnectKey) {
                        ForEach(visibleTargets, id: \.connectKey) { target in
                            Text("\(target.connectKey) (\(target.state))")
                                .tag(Optional(target.connectKey))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                    .labelsHidden()
                }
                
                Divider()
                    .frame(height: 20)
                
                // Start/Stop Button
                Button {
                    if hilog.isStreaming {
                        hilog.stopStreaming()
                    } else {
                        hilog.startStreaming(config: appModel.config)
                    }
                } label: {
                    Image(systemName: hilog.isStreaming ? "stop.fill" : "play.fill")
                        .font(.system(size: 14))
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(selectedTarget?.isOnline == false)
                .help(hilog.isStreaming ? "Stop" : "Start")
                
                // Icon Toggles
                HStack(spacing: 4) {
                    ToggleButton(
                        icon: "pause.fill",
                        isOn: $hilog.isPaused,
                        isDisabled: !hilog.isStreaming,
                        color: .orange
                    )
                    
                    ToggleButton(
                        icon: "arrow.down.to.line",
                        isOn: $autoscroll,
                        color: .blue
                    )
                    
                    ToggleButton(
                        icon: "text.line.last",
                        isOn: $lineWrap,
                        color: .purple
                    )
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 4) {
                    Button {
                        hilog.copyFilteredToClipboard()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .help("Copy to clipboard")
                    
                    Button {
                        hilog.clear()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .help("Clear logs")
                }
            }
            
            // Bottom Row: Filter & Status
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    TextField("Filter logs...", text: $hilog.filterText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(maxWidth: 200)
                
                Spacer()
                
                // Status
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(hilog.isStreaming ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                        Text(hilog.isStreaming ? "Streaming" : "Stopped")
                            .font(.caption)
                    }
                    
                    Text("\(hilog.filteredLines().count) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    
                    if let err = hilog.lastError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.red)
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Log Body
    private var logBody: some View {
        ScrollViewReader { proxy in
            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    let filteredLines = hilog.filteredLines()
                    ForEach(Array(filteredLines.enumerated()), id: \.offset) { idx, line in
                        LogLineView(
                            index: idx,
                            line: line,
                            lineWrap: lineWrap
                        )
                        .id(idx)
                    }
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: hilog.filterText) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: hilog.filteredLines().count) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard autoscroll else { return }
        let filtered = hilog.filteredLines()
        if let last = filtered.indices.last {
            withAnimation(.none) {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }

    // MARK: - Computed Properties
    private var selectedTarget: HdcTarget? {
        guard let key = hilog.selectedConnectKey else { return nil }
        return appModel.hdcTargets.first(where: { $0.connectKey == key })
    }

    private var visibleTargets: [HdcTarget] {
        let sorted = appModel.hdcTargets.sorted { lhs, rhs in
            if lhs.isOnline != rhs.isOnline { return lhs.isOnline && !rhs.isOnline }
            return lhs.connectKey < rhs.connectKey
        }
        return sorted
    }
}

// MARK: - Toggle Button
private struct ToggleButton: View {
    let icon: String
    @Binding var isOn: Bool
    var isDisabled: Bool = false
    var color: Color = .accentColor
    
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(isOn ? color : Color.gray)
                .opacity(isDisabled ? 0.4 : 1)
                .frame(width: 26, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOn ? color.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.borderless)
        .disabled(isDisabled)
    }
}

// MARK: - Log Line View
private struct LogLineView: View {
    let index: Int
    let line: String
    let lineWrap: Bool
    @State private var isHovered = false
    
    private var logLevel: LogLevel {
        if line.contains(" E/") || line.contains(" F/") || line.contains(" ERROR") {
            return .error
        } else if line.contains(" W/") || line.contains(" WARN") {
            return .warning
        } else if line.contains(" I/") || line.contains(" INFO") {
            return .info
        } else if line.contains(" D/") || line.contains(" DEBUG") {
            return .debug
        }
        return .verbose
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Line number
            Text("\(index + 1)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // Log content
            Text(line)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(logLevel.color)
                .textSelection(.enabled)
                .lineLimit(lineWrap ? nil : 1)
                .fixedSize(horizontal: !lineWrap, vertical: lineWrap)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
        .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(line) // Show full line on hover
    }
}

// MARK: - Log Level
private enum LogLevel {
    case error, warning, info, debug, verbose
    
    var color: Color {
        switch self {
        case .error: return Color.red
        case .warning: return Color.orange
        case .info: return Color.primary
        case .debug: return Color.secondary
        case .verbose: return Color.gray
        }
    }
}
