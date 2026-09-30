import Foundation
import Testing
@testable import BurnlineCore

@Test func rangeAndAggregation() {
    let now = Date(timeIntervalSince1970: 2_000_000)
    let recent = UsageRecord(id: "1", agent: .claude, model: "x", timestamp: now.addingTimeInterval(-3_600), inputTokens: 100, outputTokens: 20, costUSD: 1.25, costKind: .reported)
    let old = UsageRecord(id: "2", agent: .codex, model: "x", timestamp: now.addingTimeInterval(-10 * 86_400), inputTokens: 500)
    let result = ScanResult(records: [recent, old])
    #expect(result.totals(for: .week, now: now).totalTokens == 120)
    #expect(result.totals(for: .month, now: now).totalTokens == 620)
    #expect(result.totals(for: .week, agent: .claude, now: now).costUSD == 1.25)
}

@Test func priceBookKeepsReportedCost() {
    let record = UsageRecord(id: "1", agent: .opencode, model: "gpt-5.3-codex", timestamp: .now, inputTokens: 1_000_000, costUSD: 9, costKind: .reported)
    let priced = PriceBook().pricing(record)
    #expect(priced.costUSD == 9)
    #expect(priced.costKind == .reported)
}

@Test func priceBookSplitsCacheRates() {
    let record = UsageRecord(id: "1", agent: .claude, model: "claude-opus-4-6", timestamp: .now, cacheWriteTokens: 2_000_000, cacheWrite1hTokens: 1_000_000)
    let priced = PriceBook().pricing(record)
    #expect(priced.costUSD == 16.25)
    #expect(priced.costKind == .estimated)
}

@Test func fileCacheReusesUnchangedUsage() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = directory.appending(path: "session.jsonl")
    try Data("{}\n".utf8).write(to: source)
    let cacheURL = directory.appending(path: "index.json")
    let sample = UsageRecord(id: "cached", agent: .claude, model: "test", timestamp: .now, inputTokens: 1)
    var loads = 0

    let first = FileRecordCache(url: cacheURL)
    _ = first.records(for: source, agent: .claude) { loads += 1; return [sample] }
    _ = first.records(for: source, agent: .claude) { loads += 1; return [] }
    first.save()

    let second = FileRecordCache(url: cacheURL)
    let records = second.records(for: source, agent: .claude) { loads += 1; return [] }
    #expect(loads == 1)
    #expect(records == [sample])
}
