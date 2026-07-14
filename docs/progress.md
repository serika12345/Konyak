# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 22:45 JST
- State: `paused` at the IP-P4 review gate
- Branch: `test/macos-profile-install-e2e`; based on the `main` merge of PR #59
  (`e7227b5`) and containing the final IP-S6 review commit.
- Related TODO: IP-S6 and IP-P4 are complete and removed from `docs/todo.md`.
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: gate the complete declarative profile-install path with an
  independently rerunnable macOS public-CLI E2E and an isolated GitHub Actions
  workflow, without Steam, authentication, or live third-party installers.
- Completed work:
  - added a deterministic repository-owned Windows fixture containing an
    installer, launcher, child process, real `.lnk`, and matching x86/x64 PE
    DLLs; the generated artifact includes the repository MIT `LICENSE`
  - added `scripts/run_macos_profile_install_cli_smoke.zsh`, which exercises
    digest rejection before mutation, declared action and HTTPS ordering,
    installer execution, native DLL SHA/PE placement, override invariance,
    idempotent reinstall, binding and pin uniqueness, pinned EXE and real
    shortcut launches, child-process rules, manual apply non-mutation, metadata
    retention, and public process termination
  - added separately rerunnable Ubuntu fixture-build and macOS published-runtime
    smoke jobs in `.github/workflows/macos-profile-install-cli-smoke.yml`; the
    downstream job consumes the fixture artifact and complete runtime-owner
    manifest rather than rebuilding Wine
  - isolated work, runtime, data, config, home, resource cache, runtime manifest
    cache, HTTPS port, and ephemeral CA state; destructive roots require an
    ownership marker except for a symlink-free repository default
  - made cleanup attempt every registered bottle, preserve an original nonzero
    status, promote cleanup failure after a successful body to exit 70, and
    write portable per-bottle results plus a versioned `smoke-result.json`
  - preserved the validated runtime-owner source manifest and its SHA-256 in the
    evidence artifact, with URL, local-path, and default manifest sources all
    resolved through the maintained runtime preparation script
  - completed separate investigation, implementation, and independent result
    audit workstreams; every high and medium finding was fixed and the final
    audit found no remaining PR blocker
- Remaining work:
  - amend the verified implementation and documentation into the branch commit,
    push the branch, and open the IP-P4 pull request
  - let GitHub execute the new macOS 15 workflow; it has not run in Actions yet
  - after review and merge, continue user profile storage, canonical
    import/export, editing, and sharing work from `docs/todo.md`
- Next action: push the final commit, open the pull request, and stop for review.
- Verification performed:
  - `direnv allow`: passed after the `flake.nix` change
  - `nix develop -c zsh -lc 'just verify'`: passed on the final implementation;
    Flutter 507 tests, CLI 550 tests, custom-lint 3 tests, release automation 4
    tests, macOS runtime preparation 6 tests, and fixture 13 tests passed
  - `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint`: passed independently in the Nix dev shell
  - the initial isolated full smoke installed complete runtime
    `crossover-26.1.0-konyak.4` through public `install-macos-wine` and completed
    the full workflow from 2026-07-14 22:04:19 to 22:07:34 JST with exit 0
  - the final-code success smoke ran from 2026-07-14 22:38:30 to 22:40:31 JST;
    `smoke-result.json` records original/final exit 0 and no cleanup failure
  - the final-code timeout smoke ran from 2026-07-14 22:40:59 to 22:42:22 JST;
    it timed out at the intended public `inspect-bottle` operation and records
    original/final exit 124 with no cleanup failure
  - both final runs terminated `profile-fixture-failure` and
    `profile-fixture-success` through the public CLI with exit 0 and
    `hasFailures: false`; post-run `ps` and `lsof` found no related process or
    TCP 18443 listener, the resource cache was empty, and the private CA was
    removed
  - final success evidence is retained under
    `.dart_tool/konyak/macos-profile-install-cli-smoke-ip-s6-final-success-evidence/logs`;
    final timeout evidence is retained under
    `.dart_tool/konyak/macos-profile-install-cli-smoke-ip-s6-final-timeout-evidence/logs`
  - both artifacts validate runtime manifest SHA-256
    `f767196724a7daeee12d307784b1d5bd476968610e18e62b64328a1877c2de6e`
  - independent workflow audit confirmed valid YAML, read-only permissions,
    disabled persisted checkout credentials, appropriate path filters, narrow
    rerunnable jobs, and no runtime submodule or parent runtime dependency change
- Remaining risk:
  - the workflow consumes the runtime owner's published `latest` manifest; the
    archived manifest and component SHA-256 values make the selected inputs
    auditable, but the release reference itself remains mutable
  - the new workflow has only local syntax, contract, and dynamic validation
    until GitHub Actions runs it on the pull request
  - the separate Steam `d3dcompiler_47` acquisition compliance issue remains a
    release blocker in `docs/todo.md`; the synthetic fixture does not resolve or
    depend on those live Microsoft DLL resources
