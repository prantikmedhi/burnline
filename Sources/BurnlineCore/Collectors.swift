import Foundation

public protocol UsageCollector: Sendable {
    var agent: AgentID { get }
    func collect() throws -> [UsageRecord]
}

public struct ClaudeCollector: UsageCollector {
    public let agent = AgentID.claude
    let root: URL
    let fileCache: FileRecordCache?

    public init(home: URL) { self.init(home: home, fileCache: nil) }

    init(home: URL, fileCache: FileRecordCache?) {
        let configured = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"]
        root = configured.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
            ?? home.appending(path: ".claude")
        self.fileCache = fileCache
    }

    public func collect() throws -> [UsageRecord] {
        let transcriptRoot = root.appending(path: "projects")
        guard FileManager.default.fileExists(atPath: transcriptRoot.path) else { return [] }
        var records: [String: UsageRecord] = [:]
        for file in files(under: transcriptRoot, extension: "jsonl") {
            let parsed: [UsageRecord]
            if let fileCache {
                guard let cached = try? fileCache.records(for: file, agent: agent, load: { try parse(file) }) else { continue }
                parsed = cached
            } else {
                guard let fresh = try? parse(file) else { continue }
                parsed = fresh
            }
            for record in parsed { records[record.id] = record }
        }
        return Array(records.values)
    }

    private func parse(_ file: URL) throws -> [UsageRecord] {
        var records: [String: UsageRecord] = [:]
        for (index, row) in try JSONL.objects(at: file, containingAll: ["\"usage\"", "\"assistant\""]).enumerated() {
            guard row.string("type") == "assistant",
                  let message = row.dictionary("message"),
                  let usage = message.dictionary("usage") else { continue }
            let requestID = row.string("requestId") ?? ""
            let messageID = message.string("id") ?? ""
            let key = requestID.isEmpty && messageID.isEmpty ? "\(file.lastPathComponent):\(index)" : "\(requestID):\(messageID)"
            guard let timestamp = parseDate(row["timestamp"]) else { continue }
            let cache = usage.dictionary("cache_creation") ?? [:]
            let oneHour = cache.int64("ephemeral_1h_input_tokens")
            let splitWrite = oneHour + cache.int64("ephemeral_5m_input_tokens")
            let flatWrite = usage.int64("cache_creation_input_tokens")
            let record = UsageRecord(
                id: "claude:\(key)",
                agent: .claude,
                model: message.string("model") ?? "unknown",
                timestamp: timestamp,
                inputTokens: usage.int64("input_tokens"),
                outputTokens: usage.int64("output_tokens"),
                cacheReadTokens: usage.int64("cache_read_input_tokens"),
                cacheWriteTokens: max(flatWrite, splitWrite),
                cacheWrite1hTokens: min(oneHour, max(flatWrite, splitWrite))
            )
            if records[key] == nil || message["stop_reason"] is String { records[key] = record }
        }
        return Array(records.values)
    }
}

public struct CodexCollector: UsageCollector {
    public let agent = AgentID.codex
    let roots: [URL]
    let fileCache: FileRecordCache?

    public init(home: URL) { self.init(home: home, fileCache: nil) }

    init(home: URL, fileCache: FileRecordCache?) {
        let configured = ProcessInfo.processInfo.environment["CODEX_HOME"]
        let base = configured.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
            ?? home.appending(path: ".codex")
        roots = [base.appending(path: "sessions"), base.appending(path: "archived_sessions")]
        self.fileCache = fileCache
    }

    public func collect() throws -> [UsageRecord] {
        var records: [UsageRecord] = []
        for root in roots where FileManager.default.fileExists(atPath: root.path) {
            for file in files(under: root, extension: "jsonl") {
                let parsed: [UsageRecord]?
                if let fileCache {
                    parsed = try? fileCache.records(for: file, agent: agent, load: { try parse(file) })
                } else {
                    parsed = try? parse(file)
                }
                if let parsed { records.append(contentsOf: parsed) }
            }
        }
        return records
    }

    func parse(_ file: URL) throws -> [UsageRecord] {
        var model = "unknown"
        var previous: [String: Int64] = [:]
        var records: [UsageRecord] = []
        for (index, row) in try JSONL.objects(at: file, containingAny: ["\"turn_context\"", "\"token_count\""]).enumerated() {
            let payload = row.dictionary("payload") ?? [:]
            if row.string("type") == "turn_context", let next = payload.string("model") { model = next }
            guard row.string("type") == "event_msg",
                  payload.string("type") == "token_count",
                  let info = payload.dictionary("info"),
                  let total = info.dictionary("total_token_usage"),
                  let timestamp = parseDate(row["timestamp"]) else { continue }
            let keys = ["input_tokens", "cached_input_tokens", "cache_write_input_tokens", "output_tokens", "reasoning_output_tokens"]
            let current = Dictionary(uniqueKeysWithValues: keys.map { ($0, total.int64($0)) })
            let reset = keys.contains { current[$0, default: 0] < previous[$0, default: 0] }
            var delta: [String: Int64] = [:]
            for key in keys { delta[key] = reset ? current[key] : current[key, default: 0] - previous[key, default: 0] }
            previous = current
            let cached = delta["cached_input_tokens", default: 0]
            let input = max(0, delta["input_tokens", default: 0] - cached)
            let output = delta["output_tokens", default: 0]
            let write = delta["cache_write_input_tokens", default: 0]
            if input + cached + output + write == 0 { continue }
            records.append(UsageRecord(
                id: "codex:\(file.lastPathComponent):\(index)",
                agent: .codex,
                model: model,
                timestamp: timestamp,
                inputTokens: input,
                outputTokens: output,
                cacheReadTokens: cached,
                cacheWriteTokens: write
            ))
        }
        return records
    }
}

public struct OpenCodeCollector: UsageCollector {
    public let agent = AgentID.opencode
    let database: URL

    public init(home: URL) {
        let xdg = ProcessInfo.processInfo.environment["XDG_DATA_HOME"]
            .map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
            ?? home.appending(path: ".local/share")
        database = xdg.appending(path: "opencode/opencode.db")
    }

    public func collect() throws -> [UsageRecord] {
        guard FileManager.default.fileExists(atPath: database.path) else { return [] }
        let sql = """
        SELECT id, time_created AS ts, model, cost,
               tokens_input, tokens_output, tokens_reasoning,
               tokens_cache_read, tokens_cache_write
        FROM session
        WHERE tokens_input > 0 OR tokens_output > 0 OR tokens_reasoning > 0
           OR tokens_cache_read > 0 OR tokens_cache_write > 0 OR cost > 0;
        """
        return try SQLiteRunner.rows(database: database, sql: sql).compactMap { row in
            guard let id = row.string("id") else { return nil }
            let model: String = {
                guard let raw = row.string("model"), let data = raw.data(using: .utf8),
                      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return row.string("model") ?? "unknown"
                }
                return object.string("id") ?? object.string("modelID") ?? "unknown"
            }()
            let storedCost = row.double("cost")
            let cost = (storedCost ?? 0) > 0 ? storedCost : nil
            return UsageRecord(
                id: "opencode:\(id)",
                agent: .opencode,
                model: model,
                timestamp: parseDate(row["ts"]) ?? Date.distantPast,
                inputTokens: row.int64("tokens_input"),
                outputTokens: row.int64("tokens_output"),
                reasoningTokens: row.int64("tokens_reasoning"),
                cacheReadTokens: row.int64("tokens_cache_read"),
                cacheWriteTokens: row.int64("tokens_cache_write"),
                costUSD: cost,
                costKind: cost == nil ? .unavailable : .reported
            )
        }
    }
}

public struct HermesCollector: UsageCollector {
    public let agent = AgentID.hermes
    let database: URL

    public init(home: URL) { database = home.appending(path: ".hermes/state.db") }

    public func collect() throws -> [UsageRecord] {
        guard FileManager.default.fileExists(atPath: database.path) else { return [] }
        let sql = """
        SELECT u.session_id || ':' || u.model || ':' || u.billing_provider AS id,
               u.model, COALESCE(u.first_seen, s.started_at) AS ts,
               u.input_tokens, u.output_tokens, u.reasoning_tokens,
               u.cache_read_tokens, u.cache_write_tokens,
               u.estimated_cost_usd, u.actual_cost_usd
        FROM session_model_usage u JOIN sessions s ON s.id = u.session_id;
        """
        return try SQLiteRunner.rows(database: database, sql: sql).compactMap { row in
            guard let id = row.string("id"), let timestamp = parseDate(row["ts"]) else { return nil }
            let actual = row.double("actual_cost_usd") ?? 0
            let estimated = row.double("estimated_cost_usd") ?? 0
            let cost = actual > 0 ? actual : (estimated > 0 ? estimated : nil)
            return UsageRecord(
                id: "hermes:\(id)",
                agent: .hermes,
                model: row.string("model") ?? "unknown",
                timestamp: timestamp,
                inputTokens: row.int64("input_tokens"),
                outputTokens: row.int64("output_tokens"),
                reasoningTokens: row.int64("reasoning_tokens"),
                cacheReadTokens: row.int64("cache_read_tokens"),
                cacheWriteTokens: row.int64("cache_write_tokens"),
                costUSD: cost,
                costKind: actual > 0 ? .reported : (estimated > 0 ? .estimated : .unavailable)
            )
        }
    }
}

public struct OpenClawCollector: UsageCollector {
    public let agent = AgentID.openclaw
    let root: URL
    let fileCache: FileRecordCache?

    public init(home: URL) { self.init(home: home, fileCache: nil) }

    init(home: URL, fileCache: FileRecordCache?) {
        let configured = ProcessInfo.processInfo.environment["OPENCLAW_STATE_DIR"]
        root = configured.map { URL(fileURLWithPath: NSString(string: $0).expandingTildeInPath) }
            ?? home.appending(path: ".openclaw")
        self.fileCache = fileCache
    }

    public func collect() throws -> [UsageRecord] {
        let agents = root.appending(path: "agents")
        guard FileManager.default.fileExists(atPath: agents.path) else { return [] }
        var output: [UsageRecord] = []
        for file in files(under: agents, extension: "jsonl") {
            let parsed: [UsageRecord]?
            if let fileCache {
                parsed = try? fileCache.records(for: file, agent: agent, load: { try parse(file) })
            } else {
                parsed = try? parse(file)
            }
            if let parsed { output.append(contentsOf: parsed) }
        }
        return output
    }

    private func parse(_ file: URL) throws -> [UsageRecord] {
        var output: [UsageRecord] = []
        for (index, row) in try JSONL.objects(at: file, containingAll: ["\"usage\"", "\"assistant\""]).enumerated() {
            guard row.string("type") == "message",
                  let message = row.dictionary("message"), message.string("role") == "assistant",
                  let usage = message.dictionary("usage"),
                  let timestamp = parseDate(row["timestamp"]) else { continue }
            let cost = usage.dictionary("cost")?.double("total")
            output.append(UsageRecord(
                id: "openclaw:\(row.string("id") ?? "\(file.lastPathComponent):\(index)")",
                agent: .openclaw,
                model: message.string("model") ?? usage.string("model") ?? "unknown",
                timestamp: timestamp,
                inputTokens: usage.int64("input"),
                outputTokens: usage.int64("output"),
                reasoningTokens: usage.int64("reasoning"),
                cacheReadTokens: usage.int64("cacheRead"),
                cacheWriteTokens: usage.int64("cacheWrite"),
                costUSD: cost,
                costKind: cost == nil ? .unavailable : .reported
            ))
        }
        return output
    }
}

public struct LocalUsageScanner: Sendable {
    public let home: URL
    public let priceBook: PriceBook

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser, priceBook: PriceBook = PriceBook()) {
        self.home = home
        self.priceBook = priceBook
    }

    public func scan() -> ScanResult {
        let cache = FileRecordCache(url: home.appending(path: "Library/Caches/Burnline/usage-index.json"))
        let collectors: [any UsageCollector] = [
            ClaudeCollector(home: home, fileCache: cache),
            CodexCollector(home: home, fileCache: cache),
            OpenCodeCollector(home: home),
            HermesCollector(home: home),
            OpenClawCollector(home: home, fileCache: cache)
        ]
        var result = ScanResult()
        for collector in collectors {
            do {
                let records = try collector.collect().map(priceBook.pricing)
                result.records.append(contentsOf: records)
                if records.isEmpty { result.issues[collector.agent] = "No local usage" }
            } catch {
                result.issues[collector.agent] = error.localizedDescription
            }
        }
        cache.save()
        return result
    }
}
