# Repository instructions

Burnline is a local-only native macOS menu bar app.

## Priorities

1. Keep collectors read-only and fail-open.
2. Never read credential tables, keychains, browser cookies, prompts, message text, tool payloads, or environment secret values.
3. Preserve the difference between reported, estimated, and unavailable cost.
4. Use Foundation, SwiftUI, and system tools before adding dependencies.
5. Keep provider-specific parsing in `BurnlineCore`; keep UI free of storage schemas.

## Sources of truth

- User behavior and acceptance: `docs/PRODUCT.md`
- Data flow and boundaries: `docs/ARCHITECTURE.md`
- On-disk schemas: `docs/PROVIDERS.md`
- Visual system: `docs/DESIGN.md`
- Security rules: `docs/SECURITY.md`
- Verification: `docs/TESTING.md`

When documents disagree, security and provider contracts beat convenience.

## Definition of done

Run:

```sh
swift test
swift build -c release
npx -y @google/design.md lint docs/DESIGN.md
```

Do not claim provider accuracy from fixture tests alone. Test changed collectors against redacted fixtures and a local smoke scan without printing message content.
