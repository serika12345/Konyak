# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-15 20:23 JST
- State: `in_progress`
- Branch: `main` at `2d019de`; v1.1.0 release preparation changes are
  uncommitted.
- Related release: `v1.1.0`, focused on macOS Steam launch support and built-in
  automatic profile installation.
- Purpose: complete and publish v1.1.0 from the verified `main` revision while
  preserving the same Nix-owned macOS build toolchain used by release CI.
- Completed work:
  - confirmed post-merge Konyak Verify run `29398320399` and macOS Profile
    Installation CLI Smoke run `29398320448` passed
  - received explicit maintainer acceptance for the v1.1.0 Steam profile's
    fixed `mozilla/fxc2` `d3dcompiler_47` acquisition sources; the resolved
    release blocker was removed from `docs/todo.md`
  - drafted release notes that separate the existing real-Steam dynamic launch
    proof from the synthetic automatic profile-install smoke and document the
    macOS-only support scope and remaining generic CEF/D3DMetal limitation
  - started the full release-candidate gates; repository verification passed,
    but the macOS release build failed while Flutter was thinning a copied
    framework
  - dynamically proved the failing candidate path selected `/usr/bin/rsync`;
    Flutter 3.41.9's exact `copyFramework` arguments copied the Nix-store 0555
    framework to another 0555 directory, so `lipo` could not create its sibling
    temporary file and returned `EACCES`
  - proved Nix rsync 3.4.1 with the same
    `--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r` contract produces a 0755 destination
    where the sibling temporary file can be created
  - changed `just macos-release` to delegate to `nix run .#macos-release`, the
    same Nix release app used by the publish workflow, instead of directly
    inheriting the login shell's host-first PATH
  - added a focused macOS toolchain regression test, included it in `just test`,
    and added the same target to the hosted macOS preparation job
  - completed an independent audit with no blocker; it reproduced the Apple
    rsync failure and Nix rsync success, confirmed the release app wrapper and
    CI use the same Nix-owned route, and passed the required static checks
- Remaining work:
  - rerun the full release-candidate gates
  - prepare and push the release commit and `v1.1.0` tag, then monitor artifact
    publication and the GitHub Release to completion
- Next action: rerun the full release-candidate gates through the corrected Nix
  app route.
- Verification performed:
  - before the route fix,
    `nix develop -c zsh -lc 'just macos-flutter-toolchain-test'` dynamically
    proved Nix rsync made the read-only framework copy writable, then failed on
    the direct-script `just macos-release` recipe as expected
  - after the route fix, the same targeted command passed and created the
    lipo-style sibling temporary file in the copied framework
  - `nixfmt --check flake.nix`, the toolchain script syntax check,
    `just verify-governance`, and `git diff --check` passed
  - independent audit: `just macos-flutter-toolchain-test`,
    `just verify-governance`, `just verify-safety`, `just format-check`,
    `just lint`, all-workflow YAML parsing, the toolchain script syntax check,
    and `git diff --check` passed
- Remaining risk:
  - the full macOS release build has not yet been rerun after the route fix
  - the new hosted macOS toolchain step has not yet run in GitHub Actions
