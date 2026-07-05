# Public Shell CLI Contract

This document defines the user-facing shell CLI surface that will be introduced
on top of the existing Flutter-to-CLI backend contract. It is a planning and
compatibility contract: the canonical commands below are the target public
shape, while the existing flat commands remain supported until a later explicit
compatibility-removal gate exists.

## Goals

- Make `konyak` usable from a user's normal shell on macOS and Linux.
- Keep the Flutter app calling a separate CLI process.
- Preserve argv boundaries. Do not build shell command strings for application
  behavior.
- Preserve existing versioned JSON stdout contracts for Flutter and automation.
- Keep stderr reserved for diagnostics.
- Keep runtime ownership with Konyak-managed runtime installers and manifests.

## Canonical Grammar

Canonical user-facing commands use this shape:

```text
konyak <group> <action> [arguments] [options]
```

The initial public command groups are:

- `bottle`
- `program`
- `runtime`
- `winetricks`
- `process`
- `update`
- `shell`

Each canonical command that can be consumed by Flutter or automation must keep
supporting `--json`. Human-readable output may be added later only for the
canonical shell commands. Existing flat commands keep their current output
contracts unless a future gate explicitly changes them.

## Canonical Commands

### Bottle

- `konyak bottle list`
- `konyak bottle show <id>`
- `konyak bottle create --name <name> [--windows-version <version>]`
- `konyak bottle rename <id> --name <name>`
- `konyak bottle move <id> --path <path>`
- `konyak bottle delete <id>`
- `konyak bottle export <id> --archive <path>`
- `konyak bottle import --archive <path>`

### Program

- `konyak program list <bottle-id>`
- `konyak program run <bottle-id> --program <path> [--settings-json <json>]`
- `konyak program pin <bottle-id> --name <name> --program <path>`
- `konyak program unpin <bottle-id> --program <path>`
- `konyak program rename <bottle-id> --program <path> --name <name>`
- `konyak program settings get <bottle-id> --program <path>`
- `konyak program settings set <bottle-id> --program <path> --settings-json <json>`

### Runtime

- `konyak runtime list`
- `konyak runtime validate <id>`
- `konyak runtime install <id> [--source-manifest <path-or-url>]`
- `konyak runtime reinstall <id> [--source-manifest <path-or-url>]`
- `konyak runtime update check <id>`
- `konyak runtime update install <id>`
- `konyak runtime import gptk --from <path>`

Runtime commands must continue to consume runtime-owner-produced manifests and
artifacts. Parent-repository CLI work must not generate, download, overlay, or
mutate runtime component payloads outside the existing managed runtime install
contracts.

### Winetricks

- `konyak winetricks list`
- `konyak winetricks run <bottle-id> --verb <verb>`

### Process

- `konyak process list`
- `konyak process kill --bottle <id> --pid <pid>`
- `konyak process kill-all [--bottle <id>]`

### Update

- `konyak update check`
- `konyak update install`

### Shell

- `konyak shell install`
- `konyak shell uninstall`
- `konyak shell status`

The `shell` group is reserved for user-level shell launcher integration. It
must not silently perform administrator writes. Packaged macOS and Linux
AppImage launchers must preserve the packaged CLI context and argv boundaries.

## Compatibility Aliases

The existing flat commands are compatibility aliases. They remain valid command
entry points for Flutter, release smokes, pinned launchers, and user scripts.
Canonical commands may dispatch to the same handlers, but the flat forms must
not be removed or silently changed before a future compatibility-removal gate.

Compatibility aliases include:

| Canonical command | Existing flat command |
| --- | --- |
| `bottle list` | `list-bottles` |
| `bottle show` | `inspect-bottle` |
| `bottle create` | `create-bottle` |
| `bottle rename` | `rename-bottle` |
| `bottle move` | `move-bottle` |
| `bottle delete` | `delete-bottle` |
| `bottle export` | `export-bottle-archive` |
| `bottle import` | `import-bottle-archive` |
| `program list` | `list-bottle-programs` |
| `program run` | `run-program` |
| `program pin` | `pin-program` |
| `program unpin` | `unpin-program` |
| `program rename` | `rename-pinned-program` |
| `program settings get` | `get-program-settings` |
| `program settings set` | `set-program-settings` |
| `runtime list` | `list-runtimes` |
| `runtime validate` | `validate-runtime` |
| `runtime install macos-wine` | `install-macos-wine` |
| `runtime install linux-wine` | `install-linux-wine` |
| `runtime import gptk` | `install-gptk-wine` |
| `runtime update check` | `check-runtime-update` |
| `runtime update install` | `install-runtime-update` |
| `winetricks list` | `list-winetricks-verbs` |
| `winetricks run` | `run-winetricks` |
| `process list` | `list-wine-processes` |
| `process kill` | `terminate-wine-process` |
| `process kill-all` | `terminate-wine-processes` |
| `update check` | `check-app-update` |
| `update install` | `install-app-update` |

Internal or host-integration commands such as `launch-pinned-program`,
`install-linux-file-associations`, `open-url`, `run-bottle-command`,
`open-bottle-location`, `open-program-location`, `check-macos-setup`,
`get-app-settings`, and `set-app-settings` remain supported flat commands.
They may receive canonical public forms later only when a PR gate defines their
user-facing semantics.

## JSON And Exit Codes

- `--json` keeps versioned JSON stdout for application state.
- JSON schemas remain stable unless a future schema-versioned contract change
  is explicitly planned.
- stderr remains diagnostic text, not application state.
- Unknown or invalid command usage keeps using command-line usage failure exit
  behavior until a future gate changes help behavior deliberately.
- C1-P2 will introduce successful exit behavior for `konyak --help`,
  `konyak help`, command-group help, and `konyak --version`.

## Deprecation Policy

Flat commands are compatibility aliases for now. A later compatibility-removal
milestone must name every command being removed or warned on, define the
migration path, update Flutter and release smoke usage first, preserve
versioned JSON behavior for supported automation paths, and stop at its own
review gate before removal.
