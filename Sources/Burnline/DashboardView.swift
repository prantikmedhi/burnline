import AppKit
import SwiftUI
import BurnlineCore

struct DashboardView: View {
    @ObservedObject var store: UsageStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let accent = Color(red: 0.36, green: 0.35, blue: 0.96)
    private let cyan = Color(red: 0.22, green: 0.72, blue: 0.95)

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 14) {
                header
                rangePicker
                summary
                agents
                footer
            }
            .padding(14)
        }
        .frame(width: 388)
        .foregroundStyle(.primary)
        .background {
            if reduceTransparency {
                Color(nsColor: .windowBackgroundColor)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }

    private var backdrop: some View {
        GeometryReader { proxy in
            if !reduceTransparency {
                Circle()
                    .fill(accent.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    .frame(width: 190, height: 190)
                    .blur(radius: 48)
                    .offset(x: proxy.size.width - 128, y: -88)
                Circle()
                    .fill(cyan.opacity(colorScheme == .dark ? 0.12 : 0.08))
                    .frame(width: 170, height: 170)
                    .blur(radius: 54)
                    .offset(x: -74, y: proxy.size.height - 112)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var header: some View {
        HStack(spacing: 11) {
            BrandLens(accent: accent)
                .frame(width: 34, height: 34)
                .liquidGlass(cornerRadius: 12, tint: accent.opacity(0.18))

            VStack(alignment: .leading, spacing: 1) {
                Text("Burnline")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text("On-device agent usage")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { Task { await store.refresh() } } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(store.isRefreshing ? 180 : 0))
                    .animation(.smooth(duration: 0.22), value: store.isRefreshing)
            }
            .buttonStyle(.plain)
            .liquidGlass(cornerRadius: 11, interactive: true)
            .disabled(store.isRefreshing)
            .accessibilityLabel("Refresh local usage")
            .help("Refresh local usage")
        }
    }

    private var rangePicker: some View {
        Picker("Time range", selection: $store.range) {
            ForEach(TimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.small)
    }

    private var summary: some View {
        let totals = store.totals()
        let activeAgents = AgentID.allCases.filter { store.totals(agent: $0).totalTokens > 0 }.count

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(totals.unpricedRecords > 0 ? "PARTIAL ESTIMATE" : "TOTAL SPEND")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.9)
                        .foregroundStyle(.secondary)

                    Text(totals.costUSD, format: .currency(code: "USD"))
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .tracking(-1.2)
                        .contentTransition(.numericText())
                        .monospacedDigit()
                }

                Spacer(minLength: 16)

                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(accent)
                    .frame(width: 42, height: 42)
                    .liquidGlass(cornerRadius: 14, tint: accent.opacity(0.20))
            }

            HStack(spacing: 8) {
                MetricPill(value: shortTokens(totals.totalTokens), label: "tokens")
                MetricPill(value: "\(activeAgents)", label: "active")
                Spacer(minLength: 0)
            }
        }
        .padding(17)
        .liquidGlass(cornerRadius: 24, tint: accent.opacity(0.07))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.range.rawValue) total spend \(totals.costUSD.formatted(.currency(code: "USD"))), \(totals.totalTokens) tokens")
    }

    private var agents: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("AGENTS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.9)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(AgentID.allCases) { agent in
                    AgentRow(
                        agent: agent,
                        totals: store.totals(agent: agent),
                        issue: store.result.issues[agent]
                    )
                    if agent != AgentID.allCases.last {
                        Divider().opacity(0.26).padding(.leading, 50)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .liquidGlass(cornerRadius: 20)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .shadow(color: statusColor.opacity(0.45), radius: 3)

            Text(store.isRefreshing ? "Reading local logs" : refreshedLabel)
                .font(.system(size: 10.5, weight: .regular))
                .foregroundStyle(.secondary)

            Spacer()

            Text("Local only")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)

            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 10.5, weight: .semibold))
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .liquidGlass(cornerRadius: 9, interactive: true)
            .accessibilityLabel("Quit Burnline")
            .help("Quit Burnline")
        }
        .padding(.horizontal, 5)
    }

    private var refreshedLabel: String {
        let update = store.refreshedAt.map { "Updated \($0.formatted(date: .omitted, time: .shortened))" } ?? "Ready"
        guard !store.result.issues.isEmpty else { return update }
        return "\(update) · \(store.result.issues.count) source issue"
    }

    private var statusColor: Color {
        if store.isRefreshing { return accent }
        return store.result.issues.isEmpty ? .green : .orange
    }

    private func shortTokens(_ value: Int64) -> String {
        switch value {
        case 1_000_000_000...: String(format: "%.1fB", Double(value) / 1_000_000_000)
        case 1_000_000...: String(format: "%.1fM", Double(value) / 1_000_000)
        case 1_000...: String(format: "%.1fK", Double(value) / 1_000)
        default: "\(value)"
        }
    }
}

private struct MetricPill: View {
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.primary.opacity(0.055), in: Capsule())
    }
}

private struct AgentRow: View {
    let agent: AgentID
    let totals: UsageTotals
    let issue: String?

    private var hasData: Bool { totals.totalTokens > 0 || totals.pricedRecords > 0 }

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 31, height: 31)
                .liquidGlass(cornerRadius: 10, tint: tint.opacity(0.15))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(agent.name)
                    .font(.system(size: 12.5, weight: .medium))
                Text(detail)
                    .font(.system(size: 10.5))
                    .foregroundStyle(issue == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            if hasData {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(totals.costUSD, format: .currency(code: "USD"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    if totals.unpricedRecords > 0 {
                        Text("partial")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("—")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var detail: String {
        if issue != nil { return "Couldn’t read local data" }
        return hasData ? "\(compact(totals.totalTokens)) tokens" : "No local usage"
    }

    private var symbol: String {
        switch agent {
        case .claude: "sparkles"
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .opencode: "terminal"
        case .hermes: "point.3.connected.trianglepath.dotted"
        case .openclaw: "pawprint.fill"
        }
    }

    private var tint: Color {
        switch agent {
        case .claude: Color(red: 0.78, green: 0.39, blue: 0.26)
        case .codex: Color(red: 0.22, green: 0.56, blue: 0.94)
        case .opencode: Color(red: 0.19, green: 0.66, blue: 0.69)
        case .hermes: Color(red: 0.43, green: 0.38, blue: 0.94)
        case .openclaw: Color(red: 0.16, green: 0.61, blue: 0.45)
        }
    }

    private func compact(_ value: Int64) -> String {
        value >= 1_000_000_000 ? String(format: "%.1fB", Double(value) / 1_000_000_000) :
        value >= 1_000_000 ? String(format: "%.1fM", Double(value) / 1_000_000) :
        value >= 1_000 ? String(format: "%.1fK", Double(value) / 1_000) : "\(value)"
    }
}

private struct BrandLens: View {
    let accent: Color

    var body: some View {
        Canvas { graphics, size in
            var curve = Path()
            curve.move(to: CGPoint(x: 4, y: size.height * 0.58))
            curve.addCurve(
                to: CGPoint(x: size.width - 4, y: size.height * 0.38),
                control1: CGPoint(x: size.width * 0.33, y: size.height * 0.05),
                control2: CGPoint(x: size.width * 0.62, y: size.height * 0.90)
            )
            graphics.stroke(curve, with: .color(.primary), style: StrokeStyle(lineWidth: 2.1, lineCap: .round))
            graphics.fill(Path(ellipseIn: CGRect(x: size.width - 7, y: size.height * 0.38 - 3, width: 6, height: 6)), with: .color(accent))
        }
        .padding(5)
        .accessibilityHidden(true)
    }
}

struct BurnlineGlyph: View {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: reduceMotion ? 10 : 0.14)) { context in
            Canvas { graphics, size in
                let phase = context.date.timeIntervalSinceReferenceDate * (active ? 4.2 : 0.85)
                let mid = size.height / 2
                var wave = Path()
                wave.move(to: CGPoint(x: 1, y: mid))
                let steps = 18
                for index in 1...steps {
                    let x = CGFloat(index) / CGFloat(steps) * (size.width - 2) + 1
                    let envelope = sin(.pi * CGFloat(index) / CGFloat(steps))
                    let y = mid + sin(CGFloat(phase) + CGFloat(index) * 0.62) * 3.6 * envelope
                    wave.addLine(to: CGPoint(x: x, y: y))
                }
                graphics.stroke(wave, with: .color(.primary), style: StrokeStyle(lineWidth: 1.55, lineCap: .round, lineJoin: .round))

                let pulse = active ? 1.0 : 0.62 + 0.18 * sin(phase)
                graphics.fill(
                    Path(ellipseIn: CGRect(x: size.width - 3.2, y: mid - 1.6, width: 3.2, height: 3.2)),
                    with: .color(.primary.opacity(pulse))
                )
            }
        }
        .frame(width: 18, height: 14)
        .accessibilityLabel("Burnline usage monitor")
    }
}

private extension View {
    @ViewBuilder
    func liquidGlass(cornerRadius: CGFloat, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(
                .regular.tint(tint).interactive(interactive),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.16), lineWidth: 0.6)
                }
        }
    }
}
