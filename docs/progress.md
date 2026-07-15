# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-15 20:59 JST
- State: `completed`
- Release revision: `dbcf702`; tag `v1.1.0`.
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
  - reran the candidate through the corrected macOS release build; the build
    completed, but `smoke-macos-runtime-install` exited 75 because its synthetic
    runtime fixture predated the `bin/cabextract` completeness requirement
  - confirmed the failing public packaged CLI `install.json` reported only
    `bin/cabextract` missing, and dynamically proved the same request succeeds
    when only that file is added without changing component metadata
  - added `bin/cabextract` to the synthetic runtime fixture and made install
    failures print `install.json` while preserving the packaged CLI exit status
  - completed the full release-candidate gate, independently audited the
    release commit, notes, macOS app, DMG, checksums, metadata, signing, packaged
    CLI, and built-in Steam profile, then pushed release commit `dbcf702` and
    annotated tag `v1.1.0`
  - published GitHub Release
    `https://github.com/serika12345/Konyak/releases/tag/v1.1.0` through Konyak
    Release run `29412944928`; verify, macOS, Linux, and publish jobs passed
  - downloaded the published macOS DMG and Linux AppImage and confirmed both
    individual checksum files and the combined `SHA256SUMS` file
- Remaining work: none for the `v1.1.0` application release.
- Next action: continue the next roadmap item from `docs/todo.md`.
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
  - the new focused governance assertion failed before implementation because
    the smoke lacked `bin/cabextract`, then passed with the fixture and
    diagnostic contract
  - `nix develop -c zsh -lc 'just smoke-macos-runtime-install'` passed against
    the existing packaged candidate app after the fixture correction
  - the smoke script syntax check, `just verify-governance`,
    `just verify-safety`, `just format-check`, `just lint`, and
    `git diff --check` passed
  - `just release-candidate-gates` passed: repository verification, 507 Flutter
    tests, 550 CLI tests, macOS release build, packaged runtime extraction, DMG
    layout, Finder integration, packaged app CLI bridge, and update handoff
  - independent artifact audit confirmed version `1.1.0+10`, CLI `1.1.0`,
    release-note scope, ad-hoc code signing, DMG contents, and candidate SHA-256
  - Konyak Release run `29412944928` passed all jobs; its macOS and Linux
    artifacts passed their platform smoke suites before publication
  - published macOS and Linux downloads passed `shasum -a 256 -c` against both
    platform checksum files and the combined `SHA256SUMS`
- Remaining risk: none blocking this release. The macOS app remains intentionally
  ad-hoc signed and unnotarized; the macOS-only Steam profile scope and generic
  CEF/D3DMetal limitation are documented in the release notes.
