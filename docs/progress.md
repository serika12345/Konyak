# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 17:21 JST
- State: `paused`
- Branch: `task/profile-installer-flow`; native-component implementation is
  committed as `2be21c1`, implementation started from `d346ecf`, and the branch
  base is `6f23f55`.
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: finish the automatic compatibility-profile installation feature by
  modeling CrossOver-aligned x86/x64 `d3dcompiler_47` placement declaratively,
  proving the complete macOS public-CLI workflow, and preparing the branch for
  one feature pull request without opening it yet.
- Completed work:
  - replaced the unreleased `dependencyWinetricksVerbs` shape with ordered,
    bounded `preInstallActions` records for `winetricks` and `nativeDll`
  - added schema, domain, CLI JSON, persisted metadata, Flutter parsing, and
    Profile Manager rendering for both action kinds, including strict external
    data validation, duplicate rejection, and full resource identity retention
  - added x86 and x64 `d3dcompiler_47` actions to the built-in Steam profile in
    the order `corefonts`, `vcrun2022`, x86 DLL, x64 DLL, `fakejapanese`, then
    SteamSetup
  - pinned both DLL resources to immutable Git commits and SHA-256 values;
    independently downloaded them and confirmed x86 PE `0x014c` targets
    `windowsSysWow64`, while x64 PE `0x8664` targets `windowsSystem32`
  - fetches and verifies every installer/native resource before any Wine-side
    action, streams copies in bounded memory, rechecks SHA and PE machine before
    same-directory atomic replacement, preserves the old target on failure,
    rejects symlink and bottle-boundary escapes, and makes matching reruns a
    no-op without writing a DLL override
  - persisted the complete ordered action list in bottle metadata and retained
    the unreleased binding invariant during both automatic install and manual
    apply replacement
  - updated the Profile Manager golden to display all ordered actions and expose
    full native resource URL/SHA audit details in a tooltip
  - added a deterministic redistributable Windows fixture with installer,
    launcher, child process, real `.lnk`, and x86/x64 DLL payloads
  - added `scripts/run_macos_profile_install_cli_smoke.zsh`, covering digest
    rejection before mutation, ordered installation, PE/SHA placement, override
    invariance, idempotent reinstall, binding and pin uniqueness, pinned EXE and
    real shortcut launch, child argv/PID evidence, manual apply non-mutation,
    metadata retention, cleanup, and public process termination
  - added separately rerunnable Ubuntu fixture-build and macOS published-runtime
    smoke jobs in `.github/workflows/macos-profile-install-cli-smoke.yml`, with
    evidence upload even when the smoke fails
  - completed an independent investigation, implementation review, and result
    audit; all high and medium findings discovered during review were fixed and
    no unresolved PR blocker remains
  - removed completed IP-S5D, IP-S6, and IP-P4 work from `docs/todo.md`
- Incident and correction:
  - the first smoke attempt at 2026-07-14 16:34 JST inherited the ambient
    `KONYAK_MACOS_WINE_HOME` and ran public `install-macos-wine --reinstall`
    once against `.dart_tool/konyak/dev-runtime/macos-wine`, the runtime used by
    the running GUI; it reinstalled the same `crossover-26.1.0-konyak.4`
    release, while bottle data and running GUI/Wine processes remained intact
  - the original incident evidence is retained under
    `.dart_tool/konyak/macos-profile-install-cli-smoke/logs`
  - the smoke now ignores that ambient variable, requires its resolved runtime
    root to be a strict descendant of its resolved work root before mutation,
    records both paths, and has static, fixture, and governance regression
    checks; the final successful run used only the isolated root
- Verification performed:
  - `direnv allow`: passed after the `flake.nix` change
  - `nix develop -c zsh -lc 'just verify'`: passed; Flutter 499 tests,
    CLI 541 tests, custom-lint 3 tests, release automation 4 tests, macOS runtime
    prepare 6 tests, and profile fixture 8 tests all passed
  - `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint`: each passed independently in the Nix dev shell
  - focused golden command passed and captured
    `apps/konyak/test/goldens/profile_manager_automatic_install.png`
  - final maintained macOS public-CLI smoke passed from 2026-07-14 17:10:00 to
    17:13:26 JST with exit 0 and 14 public CLI operations; evidence is retained
    under `.dart_tool/konyak/macos-profile-install-cli-smoke-isolated/logs`
  - independent evidence audit confirmed failure attribution, action and HTTPS
    order, installed SHA/PE values, unchanged DLL overrides, idempotent file
    identities, auto/manual metadata, pin/shortcut execution, child arguments
    and parent PIDs, cache/certificate cleanup, and process termination
  - independent live downloads matched the Steam profile exactly: x86
    `2ad0d4987fc4624566b190e747c9d95038443956ed816abfd1e2d389b5ec0851`
    (3,657,992 bytes, PE `0x014c`) and x64
    `4432bbd1a390874f3f0a503d45cc48d346abc3a8c0213c289f4b615bf0ee84f3`
    (4,346,120 bytes, PE `0x8664`)
- Remaining work:
  - open the feature pull request only after explicit user approval
  - let GitHub run the new macOS 15 workflow; it has not executed locally or in
    CI yet
  - after this PR, resume user profile storage, canonical import/export,
    editing, and sharing work under the remaining roadmap
- Remaining risks:
  - the pinned GitHub Raw URLs still depend on external availability, although
    SHA-256 verification rejects changed content
  - same-UID filesystem replacement between checks is a general local TOCTOU
    boundary; private staging, containment checks, and copy-after SHA/PE
    revalidation cover ordinary corruption and escape attempts
- Next action: present the pushed branch review package and wait for approval
  before opening the pull request.
