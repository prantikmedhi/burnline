# Testing

## Automated checks

```sh
swift test
swift build -c release
npx -y @google/design.md lint docs/DESIGN.md
```

Unit tests cover range filtering, agent filtering, cost provenance, and cache pricing. Collector changes should add redacted synthetic fixtures for deduplication, cumulative counters, resets, missing prices, malformed lines, and schema drift.

## Local smoke check

1. Build and install with `./scripts/install.sh`.
2. Confirm Burnline has no Dock icon.
3. Open the menu bar item and switch all four ranges.
4. Compare one supported agent against its own local report.
5. Confirm absent agents show a quiet empty state.
6. Disconnect the network and refresh; results should still load.
7. Watch Activity Monitor between refreshes; the animated mark should stay low-cost.

A matching local report validates parser behavior, not invoice accuracy. Subscription tools may expose token-equivalent value rather than money actually billed.

## Release gate

A release needs passing tests on the exact commit, a release build, a packaged-app launch, a clean accessibility pass with Reduce Motion enabled, and verification that the app never requests credentials or network access.
