import Foundation

public struct PriceRule: Sendable {
    public let needles: [String]
    public let input: Double
    public let output: Double
    public let cacheRead: Double
    public let cacheWrite5m: Double
    public let cacheWrite1h: Double

    public init(_ needles: [String], input: Double, output: Double, cacheRead: Double, cacheWrite5m: Double, cacheWrite1h: Double? = nil) {
        self.needles = needles
        self.input = input
        self.output = output
        self.cacheRead = cacheRead
        self.cacheWrite5m = cacheWrite5m
        self.cacheWrite1h = cacheWrite1h ?? cacheWrite5m
    }
}

public struct PriceBook: Sendable {
    public let rules: [PriceRule]

    public init(rules: [PriceRule] = PriceBook.bundledRules) {
        self.rules = rules
    }

    public func pricing(_ record: UsageRecord) -> UsageRecord {
        guard record.costUSD == nil, let rule = match(record.model) else { return record }
        var priced = record
        let output = record.outputTokens + record.reasoningTokens
        priced.costUSD = (
            Double(record.inputTokens) * rule.input +
            Double(output) * rule.output +
            Double(record.cacheReadTokens) * rule.cacheRead +
            Double(record.cacheWriteTokens - record.cacheWrite1hTokens) * rule.cacheWrite5m +
            Double(record.cacheWrite1hTokens) * rule.cacheWrite1h
        ) / 1_000_000
        priced.costKind = .estimated
        return priced
    }

    private func match(_ model: String) -> PriceRule? {
        let normalized = model.lowercased()
        return rules.first { rule in rule.needles.contains { normalized.contains($0) } }
    }

    // USD per million tokens. Ordered most-specific first. See docs/PROVIDERS.md.
    public static let bundledRules: [PriceRule] = [
        PriceRule(["gpt-6-astra"], input: 10, output: 50, cacheRead: 1, cacheWrite5m: 12.5, cacheWrite1h: 12.5),
        PriceRule(["gpt-5.6-sol", "codex-5.6-sol"], input: 4, output: 20, cacheRead: 0.4, cacheWrite5m: 5, cacheWrite1h: 5),
        PriceRule(["gpt-5.3-codex"], input: 1.75, output: 14, cacheRead: 0.175, cacheWrite5m: 1.75),
        PriceRule(["claude-mythos-5"], input: 10, output: 50, cacheRead: 1, cacheWrite5m: 12.5, cacheWrite1h: 20),
        PriceRule(["claude-opus-4-6", "claude-opus-4-5"], input: 5, output: 25, cacheRead: 0.5, cacheWrite5m: 6.25, cacheWrite1h: 10),
        PriceRule(["claude-sonnet-4"], input: 3, output: 15, cacheRead: 0.3, cacheWrite5m: 3.75, cacheWrite1h: 6),
        PriceRule(["claude-haiku-4-5"], input: 1, output: 5, cacheRead: 0.1, cacheWrite5m: 1.25, cacheWrite1h: 2)
    ]
}
