#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux release builds must run on Linux." >&2
  exit 69
fi

if [[ -z "${IN_NIX_SHELL:-}" && -z "${KONYAK_NIX_RELEASE_APP:-}" ]]; then
  echo "Run this script through: nix run .#linux-release" >&2
  echo "or: nix develop -c zsh -lc './scripts/build_linux_release.zsh'" >&2
  exit 69
fi

for command in dart flutter jq curl rsync sha256sum openssl base64; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

pubspec_version="$(awk '/^version:/ { print $2; exit }' apps/konyak/pubspec.yaml)"
build_name="${KONYAK_RELEASE_VERSION:-${pubspec_version%%+*}}"
build_number="${KONYAK_RELEASE_BUILD_NUMBER:-${pubspec_version#*+}}"
if [[ "$build_number" == "$pubspec_version" ]]; then
  build_number="1"
fi

host_arch="$(uname -m)"
case "$host_arch" in
  x86_64) appimage_arch="x86_64" ;;
  *)
    echo "Unsupported Linux release architecture: $host_arch" >&2
    exit 69
    ;;
esac

release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/linux}"
stage_root="$release_root/stage"
cli_executable="$stage_root/bin/konyak-cli"
flutter_bundle="$repo_root/apps/konyak/build/linux/x64/release/bundle"
appdir_root="$release_root/Konyak.AppDir"
usr_root="$appdir_root/usr"
bundle_resources_dir="$usr_root/share/konyak"
app_id="app.konyak.Konyak"
appdir_desktop="$appdir_root/${app_id}.desktop"
appdir_icon="$appdir_root/${app_id}.png"
artifact_basename="Konyak-${build_name}-linux-${host_arch}"
appimage_path="$release_root/${artifact_basename}.AppImage"
checksum_path="$appimage_path.sha256"
checksums_path="$release_root/SHA256SUMS"
metadata_path="$release_root/${artifact_basename}.release.json"
notes_path="$release_root/release-notes.md"
runtime_stack_manifest_path="$release_root/konyak-linux-wine-runtime-stack-source.json"
runtime_stack_signature_path="$release_root/konyak-linux-wine-runtime-stack-source.json.sig"
runtime_stack_signing_key_base64="${KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64:-}"
runtime_stack_public_key_text="${KONYAK_RUNTIME_STACK_PUBLIC_KEY:-}"
runtime_stack_public_key_path="$release_root/konyak-runtime-stack-public-key.pem"
linux_runtime_source_resolver="$repo_root/scripts/resolve_linux_runtime_source_manifest.zsh"
tool_cache_dir="$release_root/tools"
tool_path="${KONYAK_APPIMAGETOOL_PATH:-$tool_cache_dir/appimagetool-${appimage_arch}.AppImage}"
tool_url="${KONYAK_APPIMAGETOOL_URL:-https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${appimage_arch}.AppImage}"

print_flutter_linux_build_diagnostics() {
  local build_root="$repo_root/apps/konyak/build/linux"
  if [[ ! -d "$build_root" ]]; then
    echo "No Flutter Linux build directory was produced at $build_root" >&2
    return
  fi

  echo "::group::Flutter Linux CMake diagnostics" >&2
  find "$build_root" -type f \( \
    -name link.txt \
    -o -name CMakeError.log \
    -o -name CMakeOutput.log \
  \) -print \
    | sort \
    | while IFS= read -r diagnostic_file; do
        echo "----- $diagnostic_file -----" >&2
        sed -n '1,240p' "$diagnostic_file" >&2 || true
      done
  echo "::endgroup::" >&2
}

rm -rf "$stage_root" "$appdir_root"
mkdir -p "$stage_root/bin" "$release_root" "$tool_cache_dir"
rm -f \
  "$appimage_path" \
  "$checksum_path" \
  "$checksums_path" \
  "$metadata_path" \
  "$notes_path" \
  "$runtime_stack_manifest_path" \
  "$runtime_stack_signature_path" \
  "$runtime_stack_public_key_path"

if [[ ! -x "$linux_runtime_source_resolver" ]]; then
  echo "Linux runtime source manifest resolver is not executable: $linux_runtime_source_resolver" >&2
  exit 69
fi

runtime_stack_manifest_source="$(
  "$linux_runtime_source_resolver" \
    --profile release \
    --manifest-cache "$runtime_stack_manifest_path" \
    --signature-cache "$runtime_stack_signature_path" \
    --public-key-cache "$runtime_stack_public_key_path" \
    --print-manifest-path
)"
runtime_stack_resolved_signature="$(
  "$linux_runtime_source_resolver" \
    --profile release \
    --print-signature-path || true
)"
runtime_stack_resolved_public_key="$(
  "$linux_runtime_source_resolver" \
    --profile release \
    --print-public-key-path || true
)"

if [[ -n "$runtime_stack_public_key_text" ]]; then
  printf '%s\n' "$runtime_stack_public_key_text" >"$runtime_stack_public_key_path"
elif [[ -n "$runtime_stack_resolved_public_key" && -f "$runtime_stack_resolved_public_key" && ! -f "$runtime_stack_public_key_path" ]]; then
  cp "$runtime_stack_resolved_public_key" "$runtime_stack_public_key_path"
fi

if [[ -n "$runtime_stack_resolved_signature" && -f "$runtime_stack_resolved_signature" && ! -f "$runtime_stack_signature_path" ]]; then
  cp "$runtime_stack_resolved_signature" "$runtime_stack_signature_path"
fi

if [[ -n "$runtime_stack_public_key_text" && ! -f "$runtime_stack_manifest_source" ]]; then
  echo "KONYAK_RUNTIME_STACK_PUBLIC_KEY requires a resolved Linux runtime source manifest." >&2
  exit 69
fi

if [[ -n "$runtime_stack_signing_key_base64" && ! -f "$runtime_stack_manifest_source" ]]; then
  echo "KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64 requires a resolved Linux runtime source manifest." >&2
  exit 69
fi

if [[ -n "$runtime_stack_signing_key_base64" && -z "$runtime_stack_public_key_text" ]]; then
  echo "KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64 requires KONYAK_RUNTIME_STACK_PUBLIC_KEY." >&2
  exit 69
fi

if [[ -n "$runtime_stack_signing_key_base64" ]]; then
  signing_key_path="$release_root/runtime-stack-signing-key.pem"
  base64 -d <<<"$runtime_stack_signing_key_base64" >"$signing_key_path"
  openssl dgst -sha256 -sign "$signing_key_path" -out "$runtime_stack_signature_path" "$runtime_stack_manifest_path"
  rm -f "$signing_key_path"
fi

echo "Building Konyak CLI executable..."
(
  cd packages/konyak_cli
  dart compile exe bin/konyak.dart -o "$cli_executable"
)

echo "Building Flutter Linux app..."
flutter_linux_build_args=(
  --release
  --build-name "$build_name"
  --build-number "$build_number"
  --dart-define=KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli
)
(
  cd apps/konyak
  if ! flutter build linux "${flutter_linux_build_args[@]}"; then
    print_flutter_linux_build_diagnostics
    echo "Flutter Linux build failed; rerunning with verbose output..." >&2
    if ! flutter --verbose build linux "${flutter_linux_build_args[@]}"; then
      print_flutter_linux_build_diagnostics
      exit 1
    fi
  fi
)

if [[ ! -d "$flutter_bundle" ]]; then
  echo "Flutter Linux bundle was not produced at $flutter_bundle" >&2
  exit 70
fi

mkdir -p "$usr_root"
rsync -a "$flutter_bundle"/ "$usr_root"/

mkdir -p "$bundle_resources_dir/Licenses"
cp "$cli_executable" "$bundle_resources_dir/konyak-cli"
chmod 755 "$bundle_resources_dir/konyak-cli"
cp LICENSE "$bundle_resources_dir/Licenses/Konyak-MIT.txt"
cp THIRD_PARTY_NOTICES.md "$bundle_resources_dir/Licenses/THIRD_PARTY_NOTICES.md"
cp apps/konyak/assets/fonts/inter/OFL.txt "$bundle_resources_dir/Licenses/Inter-OFL.txt"
cp "$runtime_stack_manifest_path" "$bundle_resources_dir/konyak-linux-wine-runtime-stack-source.json"
if [[ -f "$runtime_stack_signature_path" ]]; then
  cp "$runtime_stack_signature_path" "$bundle_resources_dir/konyak-linux-wine-runtime-stack-source.json.sig"
fi
if [[ -f "$runtime_stack_public_key_path" ]]; then
  cp "$runtime_stack_public_key_path" "$bundle_resources_dir/konyak-runtime-stack-public-key.pem"
fi
cat >"$bundle_resources_dir/NOTICES.txt" <<EOF
Konyak is distributed under the MIT License.

Wine/Proton runtime binaries are not bundled in this application artifact.
Managed runtime components are downloaded after launch into the user's Konyak
runtime directory. Bundled license and third-party notices are included in
usr/share/konyak/Licenses.
EOF

cat >"$appdir_root/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

appdir="$(cd "$(dirname "$0")" && pwd -P)"
export KONYAK_BUNDLE_RESOURCES="$appdir/usr/share/konyak"
export KONYAK_APP_EXECUTABLE="$appdir/usr/konyak"
export KONYAK_APP_PID="$$"
if [[ -f "$appdir/app.konyak.Konyak.png" ]]; then
  export KONYAK_APP_ICON_PATH="$appdir/app.konyak.Konyak.png"
elif [[ -f "$appdir/usr/data/app_icon_256.png" ]]; then
  export KONYAK_APP_ICON_PATH="$appdir/usr/data/app_icon_256.png"
fi
if [[ -f "$KONYAK_BUNDLE_RESOURCES/konyak-linux-wine-runtime-stack-source.json" ]]; then
  export KONYAK_LINUX_WINE_STACK_MANIFEST="$KONYAK_BUNDLE_RESOURCES/konyak-linux-wine-runtime-stack-source.json"
fi
if [[ -f "$KONYAK_BUNDLE_RESOURCES/konyak-linux-wine-runtime-stack-source.json.sig" ]]; then
  export KONYAK_LINUX_WINE_STACK_SIGNATURE_URL="$KONYAK_BUNDLE_RESOURCES/konyak-linux-wine-runtime-stack-source.json.sig"
fi
if [[ -f "$KONYAK_BUNDLE_RESOURCES/konyak-runtime-stack-public-key.pem" ]]; then
  export KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH="$KONYAK_BUNDLE_RESOURCES/konyak-runtime-stack-public-key.pem"
  export KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH="$KONYAK_BUNDLE_RESOURCES/konyak-runtime-stack-public-key.pem"
fi
if [[ -n "${APPIMAGE:-}" ]]; then
  export KONYAK_APPIMAGE_PATH="$APPIMAGE"
fi
if [[ "${1:-}" == "--konyak-cli" ]]; then
  shift
  exec "$KONYAK_BUNDLE_RESOURCES/konyak-cli" "$@"
fi
exec "$appdir/usr/konyak" "$@"
EOF
chmod 755 "$appdir_root/AppRun"

cp "$usr_root/share/applications/${app_id}.desktop" "$appdir_desktop"
sed -i \
  -e 's/^Exec=.*/Exec=AppRun %f/' \
  -e "s/^Icon=.*/Icon=${app_id}/" \
  "$appdir_desktop"

cp "$usr_root/data/app_icon_256.png" "$appdir_root/.DirIcon"
cp "$usr_root/data/app_icon_256.png" "$appdir_icon"

if [[ ! -x "$tool_path" ]]; then
  echo "Downloading appimagetool..."
  curl --fail --location --output "$tool_path" "$tool_url"
  chmod 755 "$tool_path"
fi

echo "Building AppImage..."
env -u SOURCE_DATE_EPOCH \
  ARCH="$appimage_arch" \
  APPIMAGE_EXTRACT_AND_RUN=1 \
  "$tool_path" "$appdir_root" "$appimage_path"

checksum="$(sha256sum "$appimage_path" | awk '{ print $1 }')"
printf "%s  %s\n" "$checksum" "$(basename "$appimage_path")" >"$checksum_path"
cp "$checksum_path" "$checksums_path"

runtime_stack_metadata_manifest=""
runtime_stack_metadata_signature=""
runtime_stack_metadata_public_key=""
runtime_stack_metadata_manifest="$(basename "$runtime_stack_manifest_path")"
if [[ -f "$runtime_stack_signature_path" ]]; then
  runtime_stack_metadata_signature="$(basename "$runtime_stack_signature_path")"
fi
if [[ -f "$runtime_stack_public_key_path" ]]; then
  runtime_stack_metadata_public_key="$(basename "$runtime_stack_public_key_path")"
fi

jq -n \
  --arg schemaVersion "1" \
  --arg appId "konyak" \
  --arg version "$build_name" \
  --arg architecture "$host_arch" \
  --arg artifact "$(basename "$appimage_path")" \
  --arg sha256 "$checksum" \
  --arg runtimeStackManifest "$runtime_stack_metadata_manifest" \
  --arg runtimeStackSignature "$runtime_stack_metadata_signature" \
  --arg runtimeStackPublicKey "$runtime_stack_metadata_public_key" \
  '{
    schemaVersion: ($schemaVersion | tonumber),
    appId: $appId,
    version: $version,
    artifacts: [
      {
        platform: "linux",
        architecture: $architecture,
        format: "appimage",
        fileName: $artifact,
        sha256: $sha256
      }
    ],
    runtimeStack: if $runtimeStackManifest == "" then null else {
      runtimeId: "konyak-linux-wine",
      stackId: "linux-wine-runtime-stack",
      sourceManifestFileName: $runtimeStackManifest,
      signatureFileName: if $runtimeStackSignature == "" then null else $runtimeStackSignature end,
      publicKeyFileName: if $runtimeStackPublicKey == "" then null else $runtimeStackPublicKey end
    } end
  }' >"$metadata_path"

{
  printf "# Konyak %s\n\n" "$build_name"
  printf "## SHA-256\n\n"
  printf "\`\`\`text\n"
  cat "$checksums_path"
  printf "\`\`\`\n"
  printf "\n## Linux Runtime Stack\n\n"
  printf -- "- Source manifest: \`%s\`\n" "$(basename "$runtime_stack_manifest_path")"
  if [[ -f "$runtime_stack_signature_path" ]]; then
    printf -- "- Signature: \`%s\`\n" "$(basename "$runtime_stack_signature_path")"
  fi
  if [[ -f "$runtime_stack_public_key_path" ]]; then
    printf -- "- Public key: \`%s\`\n" "$(basename "$runtime_stack_public_key_path")"
  fi
} >"$notes_path"

echo "Linux release artifacts:"
echo "  $appimage_path"
echo "  $checksum_path"
echo "  $metadata_path"
echo "  $notes_path"
echo "  $runtime_stack_manifest_path"
if [[ -f "$runtime_stack_signature_path" ]]; then
  echo "  $runtime_stack_signature_path"
fi
if [[ -f "$runtime_stack_public_key_path" ]]; then
  echo "  $runtime_stack_public_key_path"
fi
