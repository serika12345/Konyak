# TODO

This list tracks remaining implementation work and deferred decisions. Fully
completed work belongs in commits, tests, release artifacts, and audited
verification output instead of checked-off backlog entries.

## Current Direction

- Konyak owns its runtime, metadata, and distribution decisions.
- arm64 macOS is the first complete runtime target.
- x86_64 Linux is the second complete runtime target.
- macOS uses a Konyak-managed macOS Wine launch plan for Windows program
  execution.
- The macOS runtime layout keeps the loader at
  `Runtimes/macos-wine/bin/wineloader` and launches programs through
  `wineloader start /unix`.
- macOS targets a Konyak-managed component stack produced by
  `serika12345/konyak-macos-runtime`; the macOS runtime stack manifest and
  runtime-owner-produced artifacts remain the source of truth.
- Linux uses the Linux Wine/Proton path and stays Vulkan-oriented.
- Flutter continues to call the backend through a separate CLI process.
- Runtime-specific details stay behind CLI/backend platform services.
- The Flutter app and Dart CLI are the source of truth for application
  behavior.
- Drop live external plist metadata from the supported model. Konyak-owned
  bottle metadata is the source of truth.
- Remove runtime verification masking and prove prefix/addon integrity through
  normal application-owned CLI execution paths.

## Next Tasks

- Capture end-to-end DLSS/MetalFX rendering proof with a redistributable or
  user-provided DLSS-capable Windows program.
  - Use Konyak's public `run-program --json` path, record backend environment,
    selected runtime/component paths, process/log evidence, and Metal HUD or
    equivalent evidence where practical.
  - Do not add proprietary or nonredistributable game payloads to CI.

## Deferred

- Split Flutter large UI files after backend boundaries are smaller.
  - Keep widgets responsible for rendering and event wiring only.
  - Move bottle/program/runtime view models and action selection out of
    `home_screen.dart`, `sidebar.dart`, `program_configuration_view.dart`, and
    `bottle_configuration_view.dart`.
  - Keep CLI process launch and failure mapping behind the existing Flutter CLI
    service boundary.
  - Verify with `just flutter-format-check`, `just flutter-analyze`, and
    `just flutter-test`; add focused widget tests when visible behavior
    changes.
- Linux ARM64 Windows execution research.
- Linux executable thumbnails for sandboxed file managers.
  - Do not make the AppImage or normal app startup mutate `/nix/store` or
    create Nix GC roots on the user's behalf.
  - Treat GNOME/Nautilus thumbnailer sandboxing as normal behavior, not as a
    user configuration problem. The thumbnailer executable must be visible from
    the file manager's sandbox when on-demand thumbnails are supported.
  - Keep the existing Windows executable file association and launcher
    registration separate from thumbnail generation.
  - Design a NixOS integration path, such as a Nix package, Home Manager
    module, or NixOS module, that installs a sandbox-visible Konyak thumbnail
    helper and registers the Freedesktop `.thumbnailer` entry.
  - Consider an app-owned pre-generation path that writes Freedesktop thumbnail
    cache PNGs for executables Konyak has already inspected, while documenting
    that this is not a substitute for arbitrary Nautilus on-demand thumbnails.
  - Preserve the dynamic finding that home-directory AppImage/wrapper
    thumbnailers are not visible to GNOME's `bwrap` thumbnailer sandbox on the
    tested NixOS/Nautilus setup.
- Add E2E tests.
  - Decide the target level before implementation: Flutter integration tests
    with a fake CLI, real CLI tests against temporary directories, or a small
    full-stack Flutter plus real CLI smoke suite.
  - Keep the E2E target separate from the default fast verification gate until
    its runtime cost and flake rate are known.
- Linux runtime packaging-owner build/check hardening.
  - Add submodule-side workflows that build and verify Linux runtime components
    from pinned source recipes before the next runtime version bump.
  - Mirror or explicitly verify the Wine archive when Konyak stops referencing
    the upstream Kron4ek release asset.
  - Keep the parent repository consuming only runtime-owner-produced complete
    source manifests and archives.
