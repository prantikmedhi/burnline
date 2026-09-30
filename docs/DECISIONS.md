# Decisions

## Native SwiftUI

The app is one menu bar surface. SwiftUI and Foundation cover it without Electron, a browser view, or a package dependency.

## Local files before private APIs

Provider usage endpoints often require credentials and measure quotas rather than cost. Burnline reads the history the local tools already own. This keeps setup at zero and avoids credential scope.

## Small price book

A short reviewed table is safer than silently fetching mutable prices and rewriting historical totals. Unknown models stay visible as unpriced. A dated remote catalog can be added later with explicit cache and history semantics.

## Minute refresh

Local history does not need a live file watcher yet. One scan per minute plus manual refresh is easier to reason about. Add incremental indexing only after profiling real large stores.

## No project analytics

Working directories and prompt content could make the app more informative, but they also turn a cost meter into a work-surveillance tool. Burnline does not collect them.
