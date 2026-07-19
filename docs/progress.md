# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-19 10:34 JST
- State: `in_progress`
- Related work: GitHub issue `#66`; PR Gate D1; branch
  `task/profile-schema-docs-contract`; base commit `bff4752`.
- Purpose: document the versioned compatibility-profile manifest from its
  runtime JSON Schema, preserve Dart semantic validation as an explicit second
  layer, and make stale generated reference documentation fail locally and in
  CI before the separately gated Pages deployment work begins.
- Completed work:
  - confirmed pull request `#65` is merged into `origin/main` at `bff4752`
  - inspected the runtime Schema, canonical manifest codec, Dart value-object
    invariants, profile library lifecycle rules, release packaging paths,
    current Pages workflow, and existing verification targets
  - created GitHub issue `#66` with source-of-truth, public layout, versioning,
    CI, Pages, and two-PR review-gate contracts
  - added D1 and D2 to `docs/todo.md` and started the D1 task branch
  - captured a failing baseline: the documentation generator/output and Schema
    annotations were absent, while all five intended Dart semantic rejection
    cases already behaved as expected
  - annotated every public v1 field, variant, and conditional without adding
    validation keywords, and assigned the five Schema-external domain rules
    stable IDs tied to behavioral tests
  - added a deterministic standard-library Markdown generator, annotation
    completeness tests, stale-output checks, and `just` generation/verification
    entry points wired into governance verification
  - added the curated public authoring, validation-layer, version-policy, and
    generated v1 reference documents under `docs/public`; linked them from the
    README and recorded their source-of-truth boundary in the architecture plan
  - exercised the documented public `validate-install-profile --json` command
    against the bundled Steam manifest; it exited 0 with the versioned validate
    mutation payload
  - completed the D1 verification matrix successfully
- Remaining work:
  - commit and push D1, open its draft pull request, then update this snapshot
    with the review URL and stop before D2 Pages work
- Next action: create the verified D1 implementation commit and draft PR.
- Verification performed:
  - `just verify-profile-schema-docs` passed with 5 Python tests and a current
    generated reference
  - `just cli-test` passed with 577 tests
  - `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint` passed
  - `git diff --check` passed
- Remaining risk: D1 deliberately does not build or deploy the curated Pages
  artifact. Until D2, the authored Markdown is reviewable in the repository but
  is not yet presented through the planned MkDocs navigation and raw Schema
  mirror.
