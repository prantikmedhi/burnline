import Foundation

public enum AgentID: String, CaseIterable, Codable, Sendable, Identifiable {
    case claude, codex, opencode, hermes, openclaw

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .opencode: "OpenCode"
        case .hermes: "Hermes"
        case .openclaw: "OpenClaw"
        }
    }
}

public enum CostKind: String, Codable, Sendable {
    case reported
    case estimated
    case unavailable
}

public struct UsageRecord: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let agent: AgentID
    public let model: String
    public let timestamp: Date
    public let inputTokens: Int64
    public let outputTokens: Int64
    public let reasoningTokens: Int64
    public let cacheReadTokens: Int64
    public let cacheWriteTokens: Int64
    public let cacheWrite1hTokens: Int64
    public var costUSD: Double?
    public var costKind: CostKind

    public init(
        id: String,
        agent: AgentID,
        model: String,
        timestamp: Date,
        inputTokens: Int64 = 0,
        outputTokens: Int64 = 0,
        reasoningTokens: Int64 = 0,
        cacheReadTokens: Int64 = 0,
        cacheWriteTokens: Int64 = 0,
        cacheWrite1hTokens: Int64 = 0,
        costUSD: Double? = nil,
        costKind: CostKind = .unavailable
    ) {
        self.id = id
        self.agent = agent
        self.model = model
        self.timestamp = timestamp
        self.inputTokens = max(0, inputTokens)
        self.outputTokens = max(0, outputTokens)
        self.reasoningTokens = max(0, reasoningTokens)
        self.cacheReadTokens = max(0, cacheReadTokens)
        self.cacheWriteTokens = max(0, cacheWriteTokens)
        self.cacheWrite1hTokens = max(0, cacheWrite1hTokens)
        self.costUSD = costUSD
        self.costKind = costKind
    }

    public var totalTokens: Int64 {
        inputTokens + outputTokens + reasoningTokens + cacheReadTokens + cacheWriteTokens
    }
}

public enum TimeRange: String, CaseIterable, Identifiable, Sendable {
    case today = "Today"
    case week = "7D"
    case month = "30D"
    case all = "All"

    public var id: String { rawValue }

    public func contains(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        switch self {
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .week:
            return date >= calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            return date >= calendar.date(byAdding: .day, value: -30, to: now)!
        case .all:
            return true
        }
    }
}

public struct UsageTotals: Sendable, Equatable {
    public var inputTokens: Int64 = 0
    public var outputTokens: Int64 = 0
    public var reasoningTokens: Int64 = 0
    public var cacheReadTokens: Int64 = 0
    public var cacheWriteTokens: Int64 = 0
    public var costUSD: Double = 0
    public var pricedRecords: Int = 0
    public var unpricedRecords: Int = 0

    public var totalTokens: Int64 {
        inputTokens + outputTokens + reasoningTokens + cacheReadTokens + cacheWriteTokens
    }

    public mutating func add(_ record: UsageRecord) {
        inputTokens += record.inputTokens
        outputTokens += record.outputTokens
        reasoningTokens += record.reasoningTokens
        cacheReadTokens += record.cacheReadTokens
        cacheWriteTokens += record.cacheWriteTokens
        if let cost = record.costUSD {
            costUSD += cost
            pricedRecords += 1
        } else {
            unpricedRecords += 1
        }
    }
}

public struct ScanResult: Sendable {
    public var records: [UsageRecord]
    public var issues: [AgentID: String]

    public init(records: [UsageRecord] = [], issues: [AgentID: String] = [:]) {
        self.records = records
        self.issues = issues
    }

    public func totals(for range: TimeRange, agent: AgentID? = nil, now: Date = Date()) -> UsageTotals {
        records.lazy
            .filter { range.contains($0.timestamp, now: now) && (agent == nil || $0.agent == agent) }
            .reduce(into: UsageTotals()) { $0.add($1) }
    }
}
