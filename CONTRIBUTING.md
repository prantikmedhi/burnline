# Contributing

Small, tested pull requests are easiest to review.

Before changing a collector, add a redacted fixture that contains only the fields needed for usage accounting. Never commit a real session, prompt, path, credential, or account identifier.

Run `swift test` and `swift build -c release`. If you change the visual system, also lint `docs/DESIGN.md` with `npx -y @google/design.md lint docs/DESIGN.md`.

A provider change should explain:

- which local version produced the new schema
- whether counters are per-turn or cumulative
- how duplicates and cache tokens are handled
- whether cost is reported or estimated
