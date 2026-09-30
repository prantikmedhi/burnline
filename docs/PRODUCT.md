# Product

## Promise

Burnline answers one question from the menu bar: what did my local coding agents use, and what did that usage cost?

It is for developers who move between agent CLIs and do not want five dashboards or another service watching their work.

## Principles

- Local history is the source. Burnline does not need provider credentials.
- Money needs provenance. Reported cost, estimated cost, and missing price are different states.
- The glance comes first. The total should be readable before the panel finishes opening.
- Quiet by default. No Dock icon, streaks, leaderboards, nags, or fake savings claims.
- Partial data beats invented data. One broken collector must not hide the others.

## Core behavior

**BL-001 — Discover installed agents.** On launch, scan the supported default data locations. An absent store appears as no local usage, not an app error.

**BL-002 — Show the combined total.** Sum only records inside the selected Today, 7D, 30D, or All range.

**BL-003 — Show each agent.** Every supported agent has a stable row with token and cost totals or a plain empty/error state.

**BL-004 — Preserve cost provenance.** Use a positive cost stored by the agent before local estimation. Do not turn unknown pricing into zero.

**BL-005 — Refresh safely.** Refresh at launch and on demand. Reads must not mutate or lock an agent store. Automatic refresh waits for incremental indexing so large histories are not repeatedly rescanned.

**BL-006 — Stay local.** Normal operation makes no network request and sends no telemetry.

**BL-007 — Keep working on drift.** Malformed records and unavailable stores are skipped or isolated to one agent.

## Non-goals

- Provider quota or rate-limit tracking
- Invoice reconciliation
- Reading API keys or browser sessions
- Budgets, blocking, or spending enforcement
- Windows or Linux UI
- Cloud sync
- Project or prompt analytics

## Acceptance

A clean macOS user can build and open a menu-only app. A user with any supported local history sees that agent without configuring an account. The range control changes both the combined total and agent rows. Unknown models produce a partial-estimate label instead of a fabricated dollar amount. `swift test` and a release build pass.
