import Foundation

struct JSONL {
    static func objects(
        at url: URL,
        containingAll required: [String] = [],
        containingAny alternatives: [String] = []
    ) throws -> [[String: Any]] {
        let requiredBytes = required.map { Data($0.utf8) }
        let alternativeBytes = alternatives.map { Data($0.utf8) }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var rows: [[String: Any]] = []
        var buffer = Data()

        func parse(_ line: Data.SubSequence) {
            guard requiredBytes.allSatisfy({ line.range(of: $0) != nil }),
                  (alternativeBytes.isEmpty || alternativeBytes.contains(where: { line.range(of: $0) != nil })),
                  let object = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any] else { return }
            rows.append(object)
        }

        while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
            buffer.append(chunk)
            var start = buffer.startIndex
            while let newline = buffer[start...].firstIndex(of: 0x0A) {
                parse(buffer[start..<newline])
                start = buffer.index(after: newline)
            }
            if start != buffer.startIndex { buffer.removeSubrange(buffer.startIndex..<start) }
        }
        if !buffer.isEmpty { parse(buffer[...]) }
        return rows
    }
}

private struct CachedFile: Codable {
    let size: Int64
    let modifiedAt: TimeInterval
    let agent: AgentID
    let records: [UsageRecord]
}

private struct CachedIndex: Codable {
    let version: Int
    var files: [String: CachedFile]
}

final class FileRecordCache: @unchecked Sendable {
    private let url: URL
    private let lock = NSLock()
    private var entries: [String: CachedFile]
    private var seen = Set<String>()

    init(url: URL) {
        self.url = url
        if let data = try? Data(contentsOf: url),
           let index = try? JSONDecoder().decode(CachedIndex.self, from: data),
           index.version == 1 {
            entries = index.files
        } else {
            entries = [:]
        }
    }

    func records(for file: URL, agent: AgentID, load: () throws -> [UsageRecord]) rethrows -> [UsageRecord] {
        let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let size = Int64(values?.fileSize ?? -1)
        let modifiedAt = values?.contentModificationDate?.timeIntervalSince1970 ?? -1
        let key = stableKey(agent.rawValue + ":" + file.path)

        if let cached = lock.withLock({ () -> CachedFile? in
            seen.insert(key)
            return entries[key]
        }), cached.size == size, cached.modifiedAt == modifiedAt, cached.agent == agent {
            return cached.records
        }

        let records = try load()
        lock.withLock {
            seen.insert(key)
            entries[key] = CachedFile(size: size, modifiedAt: modifiedAt, agent: agent, records: records)
        }
        return records
    }

    func save() {
        let data: Data? = lock.withLock {
            entries = entries.filter { seen.contains($0.key) }
            return try? JSONEncoder().encode(CachedIndex(version: 1, files: entries))
        }
        guard let data else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func stableKey(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}

extension Dictionary where Key == String, Value == Any {
    func dictionary(_ key: String) -> [String: Any]? { self[key] as? [String: Any] }
    func string(_ key: String) -> String? { self[key] as? String }
    func int64(_ key: String) -> Int64 {
        if let value = self[key] as? NSNumber { return value.int64Value }
        if let value = self[key] as? String { return Int64(value) ?? 0 }
        return 0
    }
    func double(_ key: String) -> Double? {
        if let value = self[key] as? NSNumber { return value.doubleValue }
        if let value = self[key] as? String { return Double(value) }
        return nil
    }
}

func parseDate(_ value: Any?) -> Date? {
    if let number = value as? NSNumber {
        let raw = number.doubleValue
        return Date(timeIntervalSince1970: raw > 10_000_000_000 ? raw / 1000 : raw)
    }
    guard let value = value as? String else { return nil }
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: value) { return date }
    return ISO8601DateFormatter().date(from: value)
}

func files(under root: URL, extension wanted: String) -> [URL] {
    guard let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) else { return [] }
    return enumerator.compactMap { item in
        guard let url = item as? URL,
              url.pathExtension == wanted,
              (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { return nil }
        return url
    }
}

struct SQLiteRunner {
    static func rows(database: URL, sql: String) throws -> [[String: Any]] {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = ["-readonly", "-json", database.path, sql]
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: data, encoding: .utf8) ?? "SQLite query failed"
            throw NSError(domain: "Burnline.SQLite", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
        guard !data.isEmpty else { return [] }
        return try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
    }
}
