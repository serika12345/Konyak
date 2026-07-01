---
name: konyak-advance-large
description: Use when the user explicitly selects the Konyak /advance-large agent action to advance the current large milestone to completion on a dedicated branch.
---

# Konyak /advance-large

Treat this skill invocation as if the user typed `/advance-large`.

Follow the workflow in `AGENTS.md` and the README agent action command section:
find the current large milestone in `docs/todo.md`, create or continue its
dedicated branch, advance TODO-backed small steps, run required verification
through the Nix dev shell, commit and push coherent verified steps, open a
draft PR at the large milestone review gate, then stop with a review package.
