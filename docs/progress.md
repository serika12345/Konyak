# Progress

This file records Konyak's current active work and completed state so the
project can be resumed without relying on chat history.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot, completed milestone summaries, and
handoff notes.

## Current Work Snapshot

- Timestamp: 2026-06-07 21:37 JST
- State: `paused`
- Branch: `main`
- Latest known parent commit:
  `982a35a docs: add progress handoff discipline`
- Latest known macOS runtime submodule commit:
  `e7628e0 feat: package FreeType runtime component`
- Related work: macOS 32-bit Windows executable support
- Purpose: review the plan before implementation because CrossOver supports
  32-bit Windows executables through Wine32-on-64, while Konyak currently
  claims `wine32on64` support but the submodule runtime build is still
  `--enable-win64`-only.
- Completed:
  - Compared `/Users/masato/Downloads/CrossOver.app` with Konyak's runtime
    contract.
  - Confirmed CrossOver carries `lib/wine/i386-windows`,
    `lib/wine/x86_64-windows`, and `lib/wine/x86_64-unix`, with no
    `lib/wine/i386-unix`.
  - Confirmed Konyak's submodule runtime recipe currently uses
    `--enable-win64`, which is not enough for Win32 executable support.
  - Added a reviewable TODO plan for restoring macOS 32-bit Windows executable
    support before implementation starts.
- Remaining:
  - Review the TODO plan.
  - After approval, implement the submodule runtime fix first, then update the
    parent CLI contract and run-plan behavior.
- Next action: wait for plan review. Do not implement 32-bit support until the
  TODO plan is accepted or revised.
- Verification performed:
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

## Completed Milestones

- 2026-06-07: Bara-style progress handoff discipline was added through
  `docs/progress.md` and `AGENTS.md`, so active work and continuation state can
  be recovered without chat history.
- 2026-06-07: FreeType was added to the macOS runtime stack contract in the
  parent repository and packaged as a separate component in the
  `runtime/konyak-macos-runtime` submodule. The parent repository consumes the
  submodule-produced runtime stack as the source of truth instead of adding
  runtime dependencies to the parent Nix flake.
