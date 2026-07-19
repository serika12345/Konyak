# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-19 12:06 JST
- State: `completed`
- Related work: GitHub issue `#66`; completed PR Gates D1 and D2; pull
  requests `#67` and `#68`; D2 merge commit `959f1e3`; Pages workflow run
  `29671046292`.
- Purpose: publish only the curated profile documentation through GitHub Pages,
  preserve the existing product landing page, mirror the runtime v1 Schema
  byte-for-byte, and keep build and deployment permissions separated.
- Completed work:
  - merged D1 pull request `#67` and D2 pull request `#68` into `main`
  - published only the curated product page, profile documentation, assets,
    and byte-identical runtime Schema through the Nix-pinned Pages build
  - confirmed main Pages run `29671046292` built the curated artifact, deployed
    that exact artifact, and passed its independent public URL verification
  - independently reran the public URL contract from the updated local `main`
    and confirmed the landing page, documentation routes, and exact Schema
  - removed the completed D2 gate from `docs/todo.md`
  - closed completed GitHub issue `#66` with the merge, workflow, and hosted
    verification evidence
- Remaining work: none for the profile Schema documentation and Pages gates.
- Next action: select the next planned roadmap milestone; no profile Schema
  documentation work remains active.
- Verification performed:
  - the D2 local and pull-request verification matrix passed before merge,
    including 522 Flutter tests and 577 CLI tests through `just verify`
  - main Pages run `29671046292` passed build, deploy, and post-deploy URL jobs
  - `just pages-url-check "https://serika12345.github.io/Konyak/"` passed after
    deployment
  - GitHub Pages reports workflow-based publishing from `main`, public access,
    and enforced HTTPS
- Remaining risk: no browser backend was available for a visual hosted-page
  capture. The CI and independent semantic HTTP checks passed, including local
  link resolution, required content, and byte-identical Schema verification.
