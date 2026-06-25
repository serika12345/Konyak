{
  description = "Konyak development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ]
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;

          dartFlutterPackages = with pkgs; [
            dart
            flutter
            git
          ];

          scriptRuntimePackages = with pkgs; [
            bashInteractive
            coreutils
            curl
            glslang
            gawk
            gnused
            gnutar
            gzip
            jq
            openssl
            vulkan-headers
            xz
            zstd
            zsh
          ];

          verificationPackages = with pkgs; [
            deadnix
            nixfmt
            osv-scanner
            statix
          ];

          workflowPackages = with pkgs; [
            gh
            just
            python3
            ripgrep
          ];

          linuxFlutterBuildPackages = with pkgs; [
            clang
            cmake
            fontconfig
            glib
            gtk3
            libepoxy
            libxkbcommon
            ninja
            pkg-config
            util-linux
            wayland
            libx11
            libxcursor
            libxi
            libxrandr
            libxcb
          ];

          linuxReleasePackagingPackages = with pkgs; [
            curl
            gnused
            openssl
            rsync
          ];

          linuxHostRuntimePackages = with pkgs; [
            dbus
            pkgsCross.mingwW64.stdenv.cc
            vulkan-loader
            vulkan-tools
            vulkan-validation-layers
            xdg-utils
          ];

          linuxWineHostLibraryPackages = with pkgs; [
            alsa-lib
            cups
            dbus
            fontconfig
            freetype
            gnutls
            glib
            gtk3
            libdrm
            libglvnd
            libpulseaudio
            libusb1
            libxkbcommon
            mesa
            udev
            vulkan-loader
            wayland
            libx11
            libxcomposite
            libxcursor
            libxdamage
            libxext
            libxfixes
            libxi
            libxinerama
            libxrandr
            libxrender
            libxxf86vm
            libxcb
            libxshmfence
          ];

          linuxWineHostLibraryPath =
            lib.makeLibraryPath linuxWineHostLibraryPackages
            + ":/run/opengl-driver/lib:/run/opengl-driver-32/lib";

          darwinFlutterBuildPackages = with pkgs; [
            cctools
            cocoapods
            libiconv
            rsync
            zstd
          ];

          darwinReleasePackagingPackages = with pkgs; [
            create-dmg
            resvg
          ];

          darwinVerificationPackages = with pkgs; [
            swiftformat
            swiftlint
          ];

          darwinHostRuntimePackages = with pkgs; [
            pkgsCross.mingwW64.stdenv.cc
          ];

          releaseBuildPackages =
            dartFlutterPackages
            ++ (with pkgs; [
              coreutils
              gawk
              jq
              zsh
            ]);

          devShellPackages =
            dartFlutterPackages
            ++ scriptRuntimePackages
            ++ verificationPackages
            ++ workflowPackages
            ++ lib.optionals pkgs.stdenv.isLinux (
              linuxFlutterBuildPackages ++ linuxReleasePackagingPackages ++ linuxHostRuntimePackages
            )
            ++ lib.optionals pkgs.stdenv.isDarwin (
              darwinFlutterBuildPackages
              ++ darwinReleasePackagingPackages
              ++ darwinHostRuntimePackages
              ++ darwinVerificationPackages
            );

          darwinXcodeEnvironment = ''
            if [ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]; then
              export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
              export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
              export CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
              export CXX=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
              unset LD AR AS
            fi
          '';

          releaseApps =
            lib.optionalAttrs pkgs.stdenv.isDarwin (
              let
                macosReleaseApp = pkgs.writeShellApplication {
                  name = "konyak-macos-release";
                  runtimeInputs =
                    releaseBuildPackages ++ darwinFlutterBuildPackages ++ darwinReleasePackagingPackages;
                  text = ''
                    export KONYAK_NIX_RELEASE_APP=1
                    export KONYAK_REPO_ROOT="$PWD"
                    export PUB_CACHE="''${PUB_CACHE:-$PWD/.dart_tool/pub-cache}"
                    export FLUTTER_SUPPRESS_ANALYTICS=true
                    ${darwinXcodeEnvironment}
                    exec zsh ./scripts/build_macos_release.zsh "$@"
                  '';
                };
              in
              {
                default = flake-utils.lib.mkApp { drv = macosReleaseApp; };
                macos-release = flake-utils.lib.mkApp { drv = macosReleaseApp; };
              }
            )
            // lib.optionalAttrs pkgs.stdenv.isLinux (
              let
                linuxReleaseApp = pkgs.writeShellApplication {
                  name = "konyak-linux-release";
                  runtimeInputs = releaseBuildPackages ++ linuxFlutterBuildPackages ++ linuxReleasePackagingPackages;
                  text = ''
                    export KONYAK_NIX_RELEASE_APP=1
                    export KONYAK_REPO_ROOT="$PWD"
                    export PUB_CACHE="''${PUB_CACHE:-$PWD/.dart_tool/pub-cache}"
                    export FLUTTER_SUPPRESS_ANALYTICS=true
                    exec zsh ./scripts/build_linux_release.zsh "$@"
                  '';
                };
              in
              {
                default = flake-utils.lib.mkApp { drv = linuxReleaseApp; };
                linux-release = flake-utils.lib.mkApp { drv = linuxReleaseApp; };
              }
            );
        in
        {
          formatter = pkgs.nixfmt;

          apps = releaseApps;

          checks.governance = pkgs.runCommand "konyak-governance" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            cd ${self}
            python3 scripts/verify_governance.py
            touch $out
          '';

          devShells.default = pkgs.mkShell {
            packages = devShellPackages;

            shellHook = ''
              export KONYAK_REPO_ROOT="$PWD"
              export PUB_CACHE="$PWD/.dart_tool/pub-cache"
              export FLUTTER_SUPPRESS_ANALYTICS=true
              ${lib.optionalString pkgs.stdenv.isLinux ''
                export KONYAK_RUNTIME_PROFILE="development"
                export KONYAK_LINUX_WINE_HOME="$PWD/.dart_tool/konyak/dev-runtime/linux-wine"
                export KONYAK_DEV_LINUX_WINE_STACK_MANIFEST="$PWD/.dart_tool/konyak/dev-runtime-source/linux-wine-stack/konyak-linux-wine-runtime-stack-source.json"
                export KONYAK_LINUX_WINE_LIBRARY_PATH="${linuxWineHostLibraryPath}"
              ''}
              ${lib.optionalString pkgs.stdenv.isDarwin darwinXcodeEnvironment}
              ${lib.optionalString pkgs.stdenv.isDarwin ''
                export KONYAK_RUNTIME_PROFILE="development"
                export KONYAK_MACOS_WINE_HOME="$PWD/.dart_tool/konyak/dev-runtime/macos-wine"
                macos_runtime_reference="$PWD/runtime/macos-wine-release.json"
                macos_runtime_reference_value() {
                  python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))[sys.argv[2]])' "$macos_runtime_reference" "$1"
                }
                export KONYAK_DEV_MACOS_RUNTIME_RELEASE_REPO="''${KONYAK_DEV_MACOS_RUNTIME_RELEASE_REPO:-$(macos_runtime_reference_value repository)}"
                export KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG="''${KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG:-$(macos_runtime_reference_value defaultReleaseTag)}"
                macos_runtime_source_manifest_file_name="$(macos_runtime_reference_value sourceManifestFileName)"
                if [ -z "''${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-}" ]; then
                  if [ "''${KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG}" = "latest" ]; then
                    export KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="https://github.com/''${KONYAK_DEV_MACOS_RUNTIME_RELEASE_REPO}/releases/latest/download/$macos_runtime_source_manifest_file_name"
                  else
                    export KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="https://github.com/''${KONYAK_DEV_MACOS_RUNTIME_RELEASE_REPO}/releases/download/''${KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG}/$macos_runtime_source_manifest_file_name"
                  fi
                fi
                export KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT="$PWD/scripts/prepare_macos_dev_runtime_stack.zsh"
              ''}
              if [ -t 1 ]; then
                echo "Konyak dev shell ready. Run: just --list" >&2
              fi
            '';
          };
        }
      );
}
