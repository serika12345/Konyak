# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
after verification; Git history and test results are the durable record.

Use `docs/todo.md` for the actionable backlog and long-running milestones.

## Current Work Snapshot

- Timestamp: 2026-07-14 11:12 JST
- State: `paused`
- Branch: `task/profile-installer-flow`; the latest committed prerequisite is
  `3d68718`, IP-S5O is verified in the current worktree, and the branch base is
  `6f23f55`.
- Related TODO: `docs/todo.md` Next Tasks, "Build a distributable compatibility
  profile system".
- Related issue: <https://github.com/serika12345/Konyak/issues/44>
- Purpose: let users author, validate, import, export, install, and share
  declarative compatibility profiles without adding application-specific app or
  runtime branches.
- Completed work:
  - inspected the existing profile schema, domain model, CLI contracts,
    Profile Manager, winetricks planner, resource download support, persisted
    bindings, and runtime smoke boundaries
  - split the automatic profile installation work into IP-P1 through IP-P4 in
    `docs/todo.md`
  - confirmed that profile compatibility is not required before the first
    release, so IP-P1 updates the current schema directly
  - made one immutable HTTPS installer resource mandatory in profile schema 1
    and added matching JSON Schema, Dart semantic, CLI inspect, and Flutter
    parser validation
  - restricted installer resources to HTTPS URLs with a host and no userinfo or
    fragment, 64-character SHA-256 values, and safe `.exe` or `.msi` basenames
  - bounded dependency winetricks verbs and preserved their declared order
  - restricted managed program paths to absolute C-drive `.exe` paths without
    empty, dot, dot-dot, or NUL components
  - added the official Steam installer URL and a dynamically verified payload
    digest to the built-in Steam profile
  - completed an independent implementation audit and corrected its Flutter
    external-data validation finding
  - committed the completed installer manifest/read contract as `a5da3e4`
  - accepted the review gate and changed the delivery plan to keep IP-P2
    through IP-P4 on this feature branch, with one pull request after the full
    automatic installation feature is complete
  - added the public `install-program-profile` CLI command with versioned final
    JSON and optional stdout JSONL stage progress
  - added download-before-execution preflight for profile platform, complete
    host runtime and runner kind, bottle Windows version, every declared
    winetricks verb, and every installer/dependency plan
  - added a profile-owned HTTPS-only resource fetcher with redirect, timeout,
    and size limits, private exclusive staging, SHA-256 verification, typed
    cleanup, and no shell execution
  - added installer-only macOS `start /wait /unix` planning without changing
    normal program launch, plus MSI and Linux installer planning
  - made installer and dependency startup/non-zero failures stop all later
    stages, verified managed executables stay inside `drive_c`, and persisted
    profile bindings only after complete success
  - persisted the built-in manifest digest, source identity, installer resource
    identity, managed path, and compatibility profile identity directly in the
    unreleased binding shape
  - completed an independent IP-P2 audit, dynamically reproduced and fixed a
    cache-directory symlink escape, and added a nine-case public CLI failure
    matrix plus manual apply/repair no-installer contracts
  - added a Flutter contract for the versioned profile-install JSONL stream,
    with typed stages, dependency context, states, and invalid-record handling
  - added the `install-program-profile` Flutter client path with streamed
    progress and explicit success/failure results
  - made Profile Manager show the profile source, manifest SHA-256, installer
    URL and SHA-256, and numbered winetricks dependency order before execution
  - added visibly separate automatic-install and manual-apply decisions;
    automatic installation streams CLI stage progress and reloads the bottle
    only after the CLI reports success
  - captured the new Profile Manager golden and covered both the automatic
    install flow and the retained manual apply flow with widget tests
  - reproduced the GUI checkpoint failure through public `list-bottles --json`:
    one old unreleased profile binding makes the catalog return exit 74, while
    an isolated equivalent current binding returns exit 0
  - confirmed that the hidden bottle still reserves its storage identity, so
    creating the same visible name returns a conflict with no GUI recovery path
  - changed bottle listing to preserve valid records and return invalid storage
    entries separately, with one writable-first storage-ID namespace across
    configured and fallback catalogs
  - added `repair-bottle-metadata <storage-id> --action
    discard-invalid-profiles --json`, which revalidates the record, writes an
    exclusive backup, and atomically removes only incompatible profile bindings
  - rejected traversal, path mismatch, symbolic links, arbitrary corruption,
    and lower-priority duplicate repair targets without mutating bottle contents
  - made Flutter show invalid bottles in a dedicated sidebar section with cause
    and path details, a separate confirmation, blocking progress, success reload
    and backup notice, and a retained recovery row after failure
  - captured and inspected the invalid-bottle recovery golden and completed an
    independent implementation audit after correcting its custom-lint finding
  - repaired the previously hidden bottle through the macOS GUI and launched
    the Steam installer from Profile Manager
  - corrected automatic installation to run every declared winetricks
    dependency in manifest order before starting the Windows installer
  - kept download and digest verification before Wine-side mutations, released
    the staged installer exactly once on dependency failure, and prevented
    installer launch, EXE verification, and persistence after such a failure
  - completed an independent dependency-order audit with no blocking findings
- Remaining work:
  - repeat the Profile Manager automatic-install GUI inspection with the
    corrected dependency-first ordering
  - complete IP-P4 after the GUI checkpoint is accepted
  - after the automatic installation path is stable, resume user profile
    storage, canonical import/export, editing, and sharing work
- Next action: repeat Profile Manager automatic installation and confirm the
  visible `corefonts` stage completes before SteamSetup starts. Do not begin
  IP-P4 before that GUI review.
- Verification performed:
  - TDD red states captured for the new CLI/domain and Flutter parser contracts
  - `just cli-format-check`, `just cli-analyze`, and `just cli-test` passed; 487
    CLI tests passed
  - `just flutter-format-check`, `just flutter-analyze`, and
    `just flutter-test` passed; 477 Flutter tests passed after the final parser
    hardening
  - `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint` passed
  - the independent audit dynamically proved the old deterministic digest
    directory could follow a symlink and overwrite a file outside the cache;
    six hardened resource-boundary tests passed after moving to private unique
    staging with real-path containment
  - the remaining same-UID active symlink-race boundary is documented in the
    fetcher: Dart cannot pass an `O_NOFOLLOW` descriptor to curl, while the
    private mode-0700 staging prevents hostile profiles and other users from
    supplying the raced path
  - real network download and Wine installer execution were deliberately
    deferred to the maintained synthetic public-CLI smoke in IP-P4
  - captured the expected TDD red state before adding the Flutter progress
    contract and Profile Manager actions
  - targeted progress parser/client tests, automatic-install widget flow,
    retained manual-apply widget flow, and the new golden test passed
  - `just flutter-format-check`, `just flutter-analyze`, and
    `just flutter-test` passed with 484 Flutter tests
  - `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint` passed against the final IP-P3 diff
  - visually inspected
    `apps/konyak/test/goldens/profile_manager_automatic_install.png` at
    1040x720; source identity, manifest digest, installer URL and digest,
    dependency order, and both actions are visible
  - at 2026-07-14 10:07:38 JST, the real public CLI reproduced the hidden
    bottle failure with exit 74; isolated old/current binding fixtures returned
    exit 74/0 respectively, dynamically proving the old `profiles` entry is the
    material cause rather than the bottle base record
  - after IP-S5R, the same real public CLI returned exit 0 with one unique,
    actionable `invalidProgramProfiles` entry; no repair was run against user
    data
  - isolated public-CLI audit proved the pre-repair partial list, byte-identical
    backup, canonical metadata with only `profiles` removed, unchanged prefix
    sentinel, and valid post-repair list; arbitrary corruption returned exit 65
    without a backup or metadata mutation
  - CLI format, custom lint, analysis, and all 496 CLI tests passed; Flutter
    format, custom lint, analysis, and all 495 Flutter tests passed
  - final `just verify-governance`, `just verify-safety`, `just format-check`,
    and `just lint` passed after keeping filesystem work in `src/io`, extracting
    the focused recovery loader, and registering generated localization outputs
  - visually inspected
    `apps/konyak/test/goldens/invalid_bottle_recovery.png` at 1040x720; the
    usable bottle, repair entry, cause, path, and explicit discard action are
    visible without clipping or overlap
  - at 2026-07-14 11:06 JST, focused public-command and orchestration tests
    dynamically confirmed the incorrect baseline request order was installer,
    `corefonts`, then `vcrun2022`
  - captured the dependency-first TDD red state, then proved the corrected
    request order is `corefonts`, `vcrun2022`, installer and the progress order
    is preflight, download, verification, dependencies, installer, cleanup,
    managed-program verification, and persistence
  - dependency startup/non-zero audit cases issued no installer request, made
    no verifier or persistence call, released the fetched resource once, and
    preserved typed dependency failure context; 15 focused tests and all 497
    CLI tests passed
  - the Steam installer returned HTTP 200 with no redirect and 2,380,800 bytes;
    its SHA-256 matched
    `7d3654531c32d941b8cae81c4137fc542172bfa9635f169cb392f245a0a12bcb`
  - `git diff --check` passed
