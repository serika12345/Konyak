# Progress

This file records Konyak's current active work and completed state so the
project can be resumed without relying on chat history.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot, completed milestone summaries, and
handoff notes.

## Current Work Snapshot

- Timestamp: 2026-06-07 21:23 JST
- State: `completed`
- Branch: `main`
- Latest known parent commit before this documentation-policy change:
  `b29f812 feat(cli): require FreeType in macOS runtime stack`
- Latest known macOS runtime submodule commit:
  `e7628e0 feat: package FreeType runtime component`
- Related work: repository policy and continuation discipline
- Purpose: adopt the useful parts of Bara's development discipline so it is
  always clear what work is active, why it is being done, what has already been
  verified, and how to resume after context is lost.
- Completed:
  - Compared Bara's `AGENTS.md` and `README.md` workflow rules with Konyak's
    existing `AGENTS.md` and `docs/todo.md`.
  - Added a Konyak-specific progress discipline to `AGENTS.md`.
  - Added this initial progress file as the current-state handoff surface.
  - Verified the repository-policy change through the required governance,
    safety, formatting, and lint gates.
- Remaining:
  - None for this documentation-policy change.
- Next action: use `docs/progress.md` before `docs/todo.md` when resuming
  unspecified work, and update this snapshot whenever active work starts,
  pauses, blocks, is superseded, or completes.
- Verification performed:
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

## Completed Milestones

- 2026-06-07: FreeType was added to the macOS runtime stack contract in the
  parent repository and packaged as a separate component in the
  `runtime/konyak-macos-runtime` submodule. The parent repository consumes the
  submodule-produced runtime stack as the source of truth instead of adding
  runtime dependencies to the parent Nix flake.
