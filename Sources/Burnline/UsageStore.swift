import Foundation
import BurnlineCore

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var result = ScanResult()
    @Published private(set) var isRefreshing = false
    @Published private(set) var refreshedAt: Date?
    @Published var range: TimeRange = .week

    private var initialRefresh: Task<Void, Never>?

    init() {
        initialRefresh = Task { [weak self] in
            await self?.refresh()
        }
    }

    deinit { initialRefresh?.cancel() }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        let next = await Task.detached(priority: .utility) { LocalUsageScanner().scan() }.value
        result = next
        refreshedAt = Date()
        isRefreshing = false
    }

    func totals(agent: AgentID? = nil) -> UsageTotals { result.totals(for: range, agent: agent) }
}
