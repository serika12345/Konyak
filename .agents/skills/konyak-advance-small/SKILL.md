---
name: konyak-advance-small
description: Use when the user explicitly selects the Konyak /advance-small agent action to advance the next small TODO-backed step on a dedicated branch.
---

# Konyak /advance-small

Treat this skill invocation as if the user typed `/advance-small`.

Follow the workflow in `AGENTS.md` and the README agent action command section:
create or continue the active gate's dedicated branch, complete the next
coherent TODO-backed small milestone, run required verification through the Nix
dev shell, commit and push the verified step, then stop with a concise review
package.
