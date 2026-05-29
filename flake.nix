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

          commonPackages = with pkgs; [
            bashInteractive
            cabextract
            curl
            dart
            deadnix
            fd
            flutter
            gh
            git
            git-lfs
            gnutar
            gzip
            jq
            just
            melos
            nixfmt
            p7zip
            python3
            ripgrep
            rsync
            statix
            tree
            unzip
            xz
            zsh
          ];

          linuxPackages = with pkgs; [
            appimage-run
            clang
            cmake
            dbus
            glib
            gtk3
            libepoxy
            libxkbcommon
            ninja
            pkg-config
            vulkan-loader
            vkd3d-proton
            vulkan-tools
            vulkan-validation-layers
            wayland
            wineWow64Packages.stable
            winetricks
            xdg-utils
            libx11
            libxcursor
            libxi
            libxrandr
            libxcb
          ];

          darwinPackages = with pkgs; [
            cocoapods
            gst_all_1.gstreamer
            libiconv
            swiftformat
            swiftlint
          ];

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
                  runtimeInputs = commonPackages ++ darwinPackages;
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
                  runtimeInputs = commonPackages ++ linuxPackages;
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
            packages =
              commonPackages
              ++ lib.optionals pkgs.stdenv.isLinux linuxPackages
              ++ lib.optionals pkgs.stdenv.isDarwin darwinPackages;

            shellHook = ''
              export KONYAK_REPO_ROOT="$PWD"
              export PUB_CACHE="$PWD/.dart_tool/pub-cache"
              export FLUTTER_SUPPRESS_ANALYTICS=true
              ${lib.optionalString pkgs.stdenv.isLinux ''
                export KONYAK_DEV_NIX_WINE_PATH="${pkgs.wineWow64Packages.stable}"
                export KONYAK_DEV_NIX_WINETRICKS_PATH="${pkgs.winetricks}"
                export KONYAK_DEV_NIX_VKD3D_PROTON_PATH="${pkgs.vkd3d-proton}"
                export KONYAK_DEV_WINE_VERSION="${pkgs.wineWow64Packages.stable.version}"
                export KONYAK_DEV_WINETRICKS_VERSION="${pkgs.winetricks.version}"
                export KONYAK_DEV_VKD3D_PROTON_VERSION="${pkgs.vkd3d-proton.version}"
                export KONYAK_RUNTIME_PROFILE="development"
                export KONYAK_LINUX_WINE_HOME="$PWD/.dart_tool/konyak/dev-runtime/linux-wine"
                ./scripts/prepare_linux_dev_runtime.zsh >/dev/null
              ''}
              ${lib.optionalString pkgs.stdenv.isDarwin darwinXcodeEnvironment}
              ${lib.optionalString pkgs.stdenv.isDarwin ''
                export KONYAK_RUNTIME_PROFILE="development"
                export KONYAK_MACOS_WINE_HOME="$PWD/.dart_tool/konyak/dev-runtime/macos-wine"
                export KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$PWD/.dart_tool/konyak/dev-runtime-source/macos-wine-stack/konyak-macos-wine-runtime-stack-source.json"
                export KONYAK_DEV_NIX_GSTREAMER_PATH="${pkgs.gst_all_1.gstreamer.out}"
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
