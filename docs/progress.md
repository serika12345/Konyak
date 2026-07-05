# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
from this file after verification; commits, releases, tests, and generated
artifacts are the durable record for finished work.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot and any handoff notes needed to resume
unfinished work.

## Current Work Snapshot

### Latest Update

- Timestamp: 2026-07-05 22:30 JST
- State: `completed`
- Branch: `task/cli-shell-c1-contract-registry`
- Active work: C1-P1 Shell CLI Contract and Command Registry.
- Related TODO: `docs/todo.md` `Public Shell CLI Milestones`,
  `C1: Canonical Command Grammar and Compatibility`, PR Gate `C1-P1 Shell CLI
  Contract and Command Registry`.
- Pull request: https://github.com/serika12345/Konyak/pull/31
- Latest implementation commit: `7b99995`.
- Purpose: establish the maintained public shell CLI contract and a small
  command registry/test foundation before changing parser behavior, so later
  help/version and hierarchical alias work has a single command taxonomy and
  compatibility source of truth.
- Completed work: added `docs/cli-shell-contract.md` with the canonical public
  command tree, JSON/exit-code compatibility rules, flat-command alias policy,
  and deprecation policy; added `cli_shell_command_registry.dart` as a small
  registry for command groups, canonical paths, help summaries, and
  compatibility aliases; added focused registry tests that compare the registry
  with the maintained contract document; marked C1-S1 and C1-P1 complete.
- Remaining work: commit, push, open a draft PR, then stop before C1-P2.
- Next action: commit the verified C1-P1 change, push
  `task/cli-shell-c1-contract-registry`, and open a draft PR.
- Verification: passed through the Nix dev shell with `just format-check`,
  `just cli-test`, `just verify-governance`, `just verify-safety`, and
  `just lint`. Focused registry coverage also passed with
  `cd packages/konyak_cli && dart test test/cli_shell_command_registry_test.dart`.
