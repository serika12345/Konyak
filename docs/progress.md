# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-19 11:04 JST
- State: `paused`
- Related work: GitHub issue `#66`; PR Gate D2; branch
  `task/profile-schema-pages`; base merge commit `d372a48`; D1 pull request
  `#67` is merged; implementation commit `0bc4e7a`; draft pull request `#68`.
- Purpose: publish only the curated profile documentation through GitHub Pages,
  preserve the existing product landing page, mirror the runtime v1 Schema
  byte-for-byte, and keep build and deployment permissions separated.
- Completed work:
  - confirmed D1 pull request `#67` was merged into `main` at `d372a48`
  - created the dedicated D2 branch from that merge
  - confirmed the official current action majors: checkout v7,
    upload-pages-artifact v5, and deploy-pages v5
  - added MkDocs 1.6.1, Material for MkDocs 9.7.6, and actionlint through the
    flake-pinned Nix environment
  - implemented strict `pages-build`, `pages-check`, and `pages-preview`
    targets around the ignored `build/pages` staging directory
  - preserved the product page at `/`, added its documentation navigation,
    generated only `docs/public` at `/docs/`, and mirrored the runtime Schema
    byte-for-byte at `/schemas/profile-v1.schema.json`
  - added artifact allowlist, required-route/content, internal-document,
    symlink, local-link, raw-Schema identity, workflow, and deployed-URL tests
  - split Pages into pull-request-safe build, main-only deployment, and
    post-deployment URL verification jobs with job-scoped permissions and a
    run-attempt-specific artifact name
  - served the artifact locally and confirmed HTTP 200 plus expected content
    for `/`, `/docs/`, `/docs/profiles/`, `/docs/profiles/schema-v1/`, and the
    byte-identical raw Schema route
  - committed and pushed the verified implementation at `0bc4e7a`
  - opened draft pull request `#68` and stopped at the D2 review gate
- Remaining work:
  - review pull request `#68` and confirm its pull-request Pages build succeeds
  - after review and merge, audit the hosted workflow and public URLs
- Next action: review draft pull request `#68`; after approval, merge it and
  confirm the main-branch Pages deploy plus post-deployment URL check succeeds.
- Verification performed:
  - captured red tests before implementation for the missing Pages builder,
    deployment verifier, workflow separation, and landing-page docs navigation
  - `direnv allow` passed after the flake change
  - `just pages-check` passed: 7 artifact tests, 3 deployment-verifier tests,
    4 workflow tests, actionlint, 5 Schema documentation tests, strict MkDocs
    build, and artifact verification
  - a local HTTP smoke with `scripts/verify_pages_deployment.py` passed for all
    required public routes and exact Schema bytes
  - `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint` passed
  - `just verify` passed, including 522 Flutter tests, 577 CLI tests, 3 custom
    lint tests, the Pages checks, and applicable repository script tests
  - `git diff --check` passed
  - pull request checks were in progress when the D2 review gate was reached
- Remaining risk: Pages deployment occurs only after merge, so this branch can
  prove the exact artifact and local HTTP routes but cannot claim the hosted URL
  is updated; the post-deploy workflow must perform that independent check. A
  visual browser preview could not be captured because no browser session is
  available in the current browser-control environment; semantic HTTP and link
  checks passed instead.
