# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 19:31 JST
- State: `paused`
- Branch: `fix/invalid-bottle-recovery`; based on the `main` merge of PR #53
  (`13c88c3`) and carrying the recovery implementation originally committed as
  `3d68718`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: keep valid bottles usable when one Konyak-owned metadata record is
  incompatible, and provide a bounded GUI recovery path instead of leaving a
  hidden bottle that still reserves its storage identity.
- Completed work:
  - merged PRs #50 through #53 for installer-resource declarations, the public
    profile-install CLI, dependency-first execution, and the Profile Manager UI
  - changed bottle listing to retain valid records and return invalid Konyak
    metadata entries as separately validated result records
  - kept one writable-first storage-ID namespace across configured and fallback
    catalogs so a hidden invalid bottle cannot be recreated under the same ID
  - added `repair-bottle-metadata <storage-id> --action
    discard-invalid-profiles --json`
  - revalidated the target before repair, wrote an exclusive byte-identical
    backup, and atomically removed only the incompatible profile bindings
  - rejected traversal, path mismatch, symbolic links, arbitrary corruption,
    and lower-priority duplicate targets without mutating bottle contents
  - added a dedicated invalid-bottle sidebar section, cause/path details,
    explicit confirmation, blocking progress, success reload, and backup notice
  - retained the recovery row after a failed repair so users can retry
  - added CLI contract, repository, Flutter parser/client, widget, localization,
    and golden coverage for the recovery path
  - hardened the recovery boundary after independent dynamic audit: storage
    IDs that require normalization or contain path separators are isolated
    without hiding valid bottles, bottle-directory symlinks never advertise a
    repair action, and Flutter validates the same storage-ID contract
  - added screenshot coverage for both the recovery details dialog and the
    destructive confirmation dialog
- Remaining work:
  - review and merge the focused invalid-bottle recovery pull request
  - continue the runtime, Steam dependency, completion-policy, pin-icon,
    native-component, and E2E-gate commits one pull request at a time
- Next action: merge the recovery pull request, then cherry-pick `10cd370` onto
  the resulting `main` for latest-development-runtime SSOT handling.
- Verification performed:
  - the original dynamic reproduction proved that one old profile binding made
    public `list-bottles --json` return exit 74 while the hidden bottle still
    reserved its storage identity
  - the original isolated public-CLI audit proved partial listing, a
    byte-identical backup, canonical metadata with only `profiles` removed,
    unchanged bottle content, and no mutation for arbitrary corruption
  - focused CLI recovery contracts passed 12 tests; focused Flutter bottle-list
    contracts passed 18 tests; the focused recovery-dialog golden test passed
  - full CLI and Flutter suites passed 500 and 503 tests respectively
  - `just verify-governance`, `just verify-safety`, `just format-check`, `just
    lint`, CLI/Flutter format and analysis gates, and `git diff --check` passed
  - the 1040x720 recovery details golden remains
    `apps/konyak/test/goldens/invalid_bottle_recovery.png` with SHA-256
    `1ccfa090f5b26cbe040eb31c4c25e0029a4886fdd370f2901ad7333504038b51`
  - the 1040x720 confirmation golden is
    `apps/konyak/test/goldens/invalid_bottle_recovery_confirmation.png` with
    SHA-256
    `39cf527d88421539010cda56fdac6b86400ae23a1b8f85df2304c89c36fbddbe`;
    both dialog images were inspected without clipping or overlap
  - an independent read-only audit dynamically exercised the public CLI with
    canonical, whitespace-boundary, separator-containing, and symlinked bottle
    fixtures; canonical repair followed by inspect and delete succeeded, unsafe
    entries remained unmodified, and the final audit reported no blockers
- Remaining risk:
  - recovery deliberately handles only incompatible profile bindings; unrelated
    or structurally corrupt metadata remains visible as invalid but is not
    rewritten automatically
  - unaddressable storage basenames are intentionally isolated rather than
    exposed through a GUI cleanup path
  - metadata replacement compares the expected bytes before writing its backup
    and temporary file but does not yet use a cross-process lock or final
    compare-and-swap immediately before rename
