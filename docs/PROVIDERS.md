# Provider contracts

This file records what Burnline reads. Local formats are not stable APIs, so every collector must fail open.

## Claude Code

Path: `${CLAUDE_CONFIG_DIR:-~/.claude}/projects/**/*.jsonl`

Usage records are `type: assistant`. Burnline reads only `timestamp`, `requestId`, `message.id`, `message.model`, `message.stop_reason`, and `message.usage` token fields. Streamed entries can repeat; the dedup key is request ID plus message ID. Cache creation prefers the 5-minute and 1-hour split when present.

Known limit: Claude JSONL may contain streaming placeholder values for fresh input and output in some versions. Burnline reports what the local transcript records and does not call Anthropic to repair it.

## Codex

Path: `${CODEX_HOME:-~/.codex}/sessions/**/*.jsonl` plus archived sessions.

`turn_context.payload.model` selects the model. `event_msg` records with `payload.type: token_count` carry cumulative totals. Burnline differences consecutive totals and treats a backwards counter as a reset. `input_tokens` includes cached input, so cached input is subtracted before pricing. `reasoning_output_tokens` is retained as a breakdown and not added to output cost twice.

## OpenCode

Path: `${XDG_DATA_HOME:-~/.local/share}/opencode/opencode.db`

Burnline opens the database with `sqlite3 -readonly`. It reads the denormalized model, time, token, and cost totals from `session`. Account, credential, message, part, and event tables are out of scope. A session crossing a selected range boundary is attributed to its creation time.

A positive stored session cost is treated as reported. Zero with non-zero tokens is treated as unknown so a matching local price can still estimate it.

## Hermes

Path: `~/.hermes/state.db`

Burnline reads `session_model_usage` joined to `sessions`. `actual_cost_usd` wins when positive, then `estimated_cost_usd`. The current aggregate timestamp is `first_seen` with session start as fallback, so a session crossing a range boundary can be attributed to its first seen date.

## OpenClaw

Path: `${OPENCLAW_STATE_DIR:-~/.openclaw}/agents/*/sessions/*.jsonl`

Burnline reads assistant `message` entries and normalized `message.usage` fields: `input`, `output`, `reasoning`, `cacheRead`, `cacheWrite`, and `cost.total`. It does not read session text or tool content.

## Pricing

Stored positive costs take precedence. The bundled estimate table is intentionally small and dated by source control. Current starter rows cover common Anthropic 4.x and current OpenAI Codex families. Unknown models remain unpriced.

Pricing sources used for the initial table:

- [OpenAI API pricing](https://platform.openai.com/docs/pricing)
- [Anthropic pricing](https://platform.claude.com/docs/en/about-claude/pricing)

Prices are USD per million tokens. They do not include enterprise agreements, cloud markups, batch discounts, data-sharing discounts, taxes, credits, subscription economics, or long-context tiers unless a rule says so.
