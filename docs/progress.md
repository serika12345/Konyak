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

- Timestamp: 2026-06-25 20:38 JST
- State: `completed`
- Branch: `main`
- Active work: making the macOS native menu bar follow Konyak's in-app
  language setting.
- Related TODO: none; user-reported native UI localization gap.
- Purpose: make the macOS menu bar update from Flutter localization strings
  when Konyak's language is set to Japanese, instead of relying only on
  AppKit's launch-time bundle localization.
- Completed work: added `ja.lproj/MainMenu.strings`, registered Japanese in the
  Xcode project localization list, added ARB-backed macOS native menu labels,
  added a Flutter bridge that sends the current localized menu titles to
  macOS, and added Swift handling that updates AppKit menu titles by their
  existing action selectors.
- Remaining work: none for Konyak-owned native menu items. The AppKit-injected
  alternate `Quit and Keep Windows` item remained OS-language-controlled in the
  smoke environment.
- Next action: commit the completed macOS native menu localization fix when
  requested.
- Verification: focused widget coverage failed before implementation because
  no `setMenuLocalization` payload was sent, then passed after the bridge was
  added; focused macOS static coverage failed before Swift handling existed,
  then passed after implementation; `flutter gen-l10n`; `plutil -lint
  apps/konyak/macos/Runner/ja.lproj/MainMenu.strings
  apps/konyak/macos/Runner.xcodeproj/project.pbxproj`; `flutter build macos
  --debug`; a runtime smoke launched
  `apps/konyak/build/macos/Build/Products/Debug/Konyak.app` with a temporary
  fake CLI returning `languageMode: "ja"` and System Events reported
  `menuBar=AppleKonyakファイル`, app menu items including `Konyak について`,
  `設定`, `アップデートを確認`, `macOS ランタイムを再インストール`, `Konyak を隠す`,
  `ほかを隠す`, `すべて表示`, `Konyak を終了`, and File menu item
  `ボトルをインポート`; System Events also listed AppKit's alternate
  `Quit and Keep Windows` item in English; `just verify-governance`; `just
  verify-safety`;
  `just flutter-format-check`; `just swift-lint`; `just flutter-analyze`;
  `just flutter-test`; `just format-check`; `just lint`.
