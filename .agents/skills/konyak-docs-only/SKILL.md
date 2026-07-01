---
name: konyak-docs-only
description: Use when the user explicitly selects the Konyak /docs-only agent action to perform documentation or policy edits only.
---

# Konyak /docs-only

Treat this skill invocation as if the user typed `/docs-only`.

Perform documentation or policy edits only. Usually stay on `main`; do not
create a branch, commit, or push unless the user explicitly requests it. Run
the required documentation and repository verification through the Nix dev
shell before reporting completion.
