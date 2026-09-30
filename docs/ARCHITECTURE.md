# Architecture

## Shape

Burnline has two targets.

- `BurnlineCore` owns discovery, read-only parsing, normalization, pricing, and aggregation.
- `Burnline` owns the menu bar scene, refresh loop, and SwiftUI presentation.

The dependency points one way: UI to core.

```text
local agent stores
       │ read only
       ▼
agent collectors ──► UsageRecord ──► PriceBook ──► ScanResult
                                                   │
                                                   ▼
                                             UsageStore
                                                   │
                                                   ▼
                                         MenuBarExtra panel
```

## Normalized record

Every usage event becomes a `UsageRecord` with an agent, model, timestamp, five token buckets, optional cost, and cost provenance. Collectors normalize cache semantics before pricing. Cost aggregation never treats `nil` as a real zero.

## Collector rules

- Claude Code deduplicates streamed assistant entries by request ID and message ID. A terminal entry replaces an earlier stream snapshot.
- Codex differences cumulative counters. Cached input is removed from ordinary input before pricing. Reasoning is a breakdown of output and is not added twice.
- OpenCode reads denormalized session token and cost totals from SQLite in read-only mode and prefers its positive stored cost.
- Hermes reads `session_model_usage` joined to `sessions` in read-only mode and prefers actual cost over estimated cost.
- OpenClaw reads assistant transcript usage and its recorded `usage.cost.total` when available.

## Failure containment

Collectors run independently. Missing directories return no records. A collector error is attached to that agent, while valid records from other agents still render. The UI keeps the previous snapshot until a refresh finishes.

## Performance

The starter scans at launch and on demand. JSONL reads prefilter raw lines before JSON decoding. Parsed usage records are cached by an opaque file key, byte size, and modification date in `~/Library/Caches/Burnline/usage-index.json`; changed files are reparsed and unchanged files are reused. SQLite is queried through macOS `/usr/bin/sqlite3` with `-readonly`. The cache stores usage metadata only, never transcript content.

## Distribution

`scripts/install.sh` produces a separate ad-hoc signed app in `~/Applications`. Public distribution later needs a Developer ID, hardened runtime, notarization, release archives, and an updater decision. Those are distribution concerns, not runtime dependencies.
