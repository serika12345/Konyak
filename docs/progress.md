# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
from this file after verification; commits, releases, tests, and generated
artifacts are the durable record for finished work.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot and any handoff notes needed to resume
unfinished work.

## Current Work Snapshot

### Latest Update

- Timestamp: 2026-07-06 22:07 JST
- State: `completed`
- Branch: `main`
- Active work: GPTK4 development runtime CI smoke verification.
- Related TODO: `docs/todo.md` now points at the next DLSS/MetalFX
  rendering-proof task.
- Pull request: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/5 merged as
  `0a09716b`; parent PR https://github.com/serika12345/Konyak/pull/39
  merged as `104e23b`; parent PR https://github.com/serika12345/Konyak/pull/40
  merged as `54f66d4`.
- Latest known completed work: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/3 merged as
  `eedc190`; parent PR https://github.com/serika12345/Konyak/pull/34 merged
  as `ab048d8`; parent PR https://github.com/serika12345/Konyak/pull/35
  merged as `0afa99f`; parent PR https://github.com/serika12345/Konyak/pull/36
  merged as `4e56d49`; parent PR https://github.com/serika12345/Konyak/pull/37
  merged as `2445a0d`; runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/4 merged as
  `472091f`; parent PR https://github.com/serika12345/Konyak/pull/38 merged
  as `3e1d5f`.
- Runtime branch: no runtime submodule changes planned; parent `main` records
  runtime submodule commit `61624ad`.
- Purpose: prove the currently installed development macOS Wine runtime with
  user-provided GPTK4/D3DMetal can run the same backend probes used by runtime
  CI.
- Workstream separation: the multi-agent tool is available, but its tool-level
  instructions allow spawning only when the user explicitly requests
  sub-agents. Investigation and audit evidence are therefore recorded here and
  in the final handoff.
- Completed work: fast-forwarded local `main` to `54f66d4`, confirmed the
  runtime submodule pointer at `61624ad`, confirmed the development runtime
  D3DMetal framework reports `CFBundleShortVersionString` `4.0b1`, ran the CI
  GPTK/D3DMetal backend smoke targets directly against
  `.dart_tool/konyak/dev-runtime/macos-wine`, ran the local CI smoke wrapper
  against a temporary copy with
  `KONYAK_GPTK_D3DMETAL_CI_SOURCE_PATH=/Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg`,
  and confirmed `list-runtimes --json` reports the `gptk-d3dmetal` component
  installed and backend available.
- Remaining work: none for this verification.
- Next action: continue with the DLSS/MetalFX rendering-proof task in
  `docs/todo.md`.
- Verification so far:
  - `plutil -p .dart_tool/konyak/dev-runtime/macos-wine/components/gptk-d3dmetal/lib/external/D3DMetal.framework/Versions/A/Resources/Info.plist`
    reported `CFBundleShortVersionString` `4.0b1`.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh .dart_tool/konyak/dev-runtime/macos-wine'`
    passed.
  - `nix develop -c zsh -lc 'KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1 runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh .dart_tool/konyak/dev-runtime/macos-wine gptk-d3d10-unsupported .dart_tool/konyak/dev-runtime-gptk4-backend-probes'`
    passed.
  - `nix develop -c zsh -lc 'KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1 runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh .dart_tool/konyak/dev-runtime/macos-wine gptk-d3d11-device .dart_tool/konyak/dev-runtime-gptk4-backend-probes'`
    passed.
  - `nix develop -c zsh -lc 'KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1 runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh .dart_tool/konyak/dev-runtime/macos-wine gptk-d3d12-device .dart_tool/konyak/dev-runtime-gptk4-backend-probes'`
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_GPTK_D3DMETAL_CI_SOURCE_PATH=/Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg ./scripts/smoke-gptk-d3dmetal-local.zsh --allow-unsupported-host --work-root /tmp/konyak-dev-runtime-gptk4-ci-smoke /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine'`
    passed: GPTK4 was detected, `gptk-d3d10-unsupported`,
    `gptk-d3d11-device`, and `gptk-d3d12-device` all passed against the
    temporary runtime copy.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development KONYAK_MACOS_WINE_HOME=/Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine dart run bin/konyak.dart list-runtimes --json | jq -e ".runtimes[] | select(.id == \"konyak-macos-wine\") | {isInstalled, libraryPath, gptkComponent: (.stack.components[] | select(.id == \"gptk-d3dmetal\")), gptkBackend: (.stack.backends[] | select(.id == \"gptk-d3dmetal\"))}"'`
    passed and reported `gptk-d3dmetal` installed with no missing paths and
    backend `isAvailable: true`.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart --plain-name "imports GPTK Wine"'`
    passed after first failing for the missing version model/CLI argument.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog imports"'`
    passed: Auto keeps the existing omitted-version argv, GPTK 3 passes
    `--gptk-version 3`, and GPTK 4 passes `--gptk-version 4`.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings GPTK import version panel matches golden" --update-goldens'`
    passed and captured `apps/konyak/test/goldens/app_settings_gptk_import_version.png`.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings GPTK import version panel matches golden"'`
    passed against the captured golden.
  - `nix develop -c zsh -lc 'just flutter-format-check && just flutter-analyze && just flutter-test'`
    passed; Flutter test reported 465 tests passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check && just verify-governance && just verify-safety && just format-check && just lint'`
    passed.
  - `nix develop -c zsh -lc 'just smoke-macos-gptk-import-cli'` passed:
    Apple GPTK 3.0 and Apple GPTK 4.0 beta 1 were installed through the public
    CLI path, `list-runtimes --json` reported `gptk-d3dmetal`, GPTK3 retained
    `atidxx64.*`, GPTK4 omitted `atidxx64.*`, neither installed active
    `d3d10.*`, and all maintained GPTK backend smokes passed. Logs:
    `.dart_tool/konyak/gptk-import-cli-smoke/logs`.
  - `nix develop -c zsh -lc 'zsh -n scripts/run_macos_gptk_import_cli_smoke.zsh && git diff --check && git -C runtime/konyak-macos-runtime diff --check && just cli-test && just verify-governance && just verify-safety && just format-check && just lint'`
    passed; `just cli-test` reported 382 tests passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/import-gptk-d3dmetal-redist.zsh scripts/prepare-gptk-d3dmetal-ci-smoke.zsh scripts/smoke-backend-device.zsh scripts/smoke-gptk-d3dmetal-local.zsh scripts/check-runtime-archive-excludes-gptk.zsh'`
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_GPTK_D3DMETAL_CI_SOURCE_PATH=/Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg ./scripts/smoke-gptk-d3dmetal-local.zsh --allow-unsupported-host --work-root /tmp/konyak-gptk4-local-smoke dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed: GPTK4 was detected, `gptk-d3d10-unsupported`,
    `gptk-d3d11-device`, and `gptk-d3d12-device` passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-gptk-d3dmetal-local.zsh --allow-unsupported-host --work-root /tmp/konyak-gptk3-local-smoke dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed: GPTK3 was detected and the same GPTK smoke targets passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#gnutar -c ./scripts/check-runtime-archive-excludes-gptk.zsh dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check && just verify-governance && just verify-safety && just format-check && just lint'`
    passed.
  - Runtime PR #4 full Build runtime CI passed, including Wine runtime,
    MoltenVK, DXMT, vkd3d, binary components, runtime stack assembly, release
    metadata, Wine32-on-64, GUI start, DXVK D3D10/D3D11, WineD3D D3D10,
    DXMT D3D11, vkd3d D3D12, and GPTK/D3DMetal backend smoke.
  - Parent PR #38 CI passed: Konyak Verify and macOS Runtime CLI Smoke.
