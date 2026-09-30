# Security

Burnline is a viewer, not an agent gateway.

## Trust boundary

The app reads usage metadata from known local paths and renders aggregates in-process. It does not send usage, paths, models, or identifiers anywhere. It does not need an account.

## Data minimization

Collectors may read only identifiers needed for deduplication, timestamps, model labels, token counters, and cost fields. They must not collect prompts, responses, tool arguments, tool output, working directories, repository names, emails, browser cookies, API keys, refresh tokens, or Keychain items.

SQLite access is read-only. OpenCode account and credential tables are prohibited. Burnline never modifies source logs. Its optional performance index contains normalized usage records and opaque hashes for source paths; it does not contain prompts, responses, tool content, or credentials.

## Cost safety

A missing price stays missing. Reported and estimated costs remain distinguishable. Combined totals can be partial and must say so.

## Distribution

The developer installer uses ad-hoc signing, which is not notarization. A public binary release needs a Developer ID, hardened runtime, notarization, a reproducible release record, and checksum publication.

Report a vulnerability through GitHub security advisories rather than a public issue.
