---
name: konyak-status
description: Use when the user explicitly selects the Konyak /konyak-status agent action to report repository status without modifying files.
---

# Konyak /konyak-status

Treat this skill invocation as if the user typed Konyak's repository
`/konyak-status` action, not the Codex IDE built-in `/status` command.

Do not modify files. Follow `AGENTS.md` and the README agent action command
section to report the current branch state, worktree status, active TODO
milestone, relevant refactoring gate, and recommended next action.
