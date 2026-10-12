{
  description = "CC Switch - All-in-One Assistant for Claude Code, Codex & Gemini CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      systemArchMap = {
        "x86_64-linux" = "x86_64";
        "aarch64-linux" = "arm64";
      };

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # sha256 hashes for each arch's .deb
      debHashes = {
        "x86_64" = "sha256-H3za4eE9fbLynq5eD5d9yLqjIK4G9UlZtwE8mVGfWwE=";
        "arm64"  = "sha256-7vKWZzuuIa3PEHInfrPjONfRBBohix3C10kjEE47f6c=";
      };

      mkPackage = pkgs:
        let
          inherit (pkgs) lib stdenv;
          arch = systemArchMap.${stdenv.hostPlatform.system};
          version = "4.0.10";
        in
        stdenv.mkDerivation {
          pname = "cc-switch";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://github.com/farion1231/cc-switch/releases/download/v${version}/CC-Switch-v${version}-Linux-${arch}.deb";
            hash = debHashes.${arch};
          };

          nativeBuildInputs = [
            pkgs.dpkg
            pkgs.autoPatchelfHook
          ];

          buildInputs = [
            pkgs.webkitgtk_4_1
            pkgs.gtk3
            pkgs.glib
            pkgs.gdk-pixbuf
            pkgs.cairo
            pkgs.pango
            pkgs.atk
            pkgs.libsoup_3
            pkgs.openssl
            pkgs.libayatana-appindicator
            pkgs.librsvg
            pkgs.libGL
            pkgs.vulkan-loader
            pkgs.dbus
            pkgs.wayland
          ];

          runtimeDependencies = [
            pkgs.libayatana-appindicator
          ];

          unpackPhase = ''
            runHook preUnpack
            dpkg-deb -x $src .
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r usr/* $out/

            # Fix desktop file Exec path
            mkdir -p $out/share/applications
            substitute "usr/share/applications/CC Switch.desktop" \
              "$out/share/applications/CC Switch.desktop" \
              --replace-fail "Exec=cc-switch" "Exec=$out/bin/cc-switch"

            runHook postInstall
          '';

          meta = with lib; {
            description = "All-in-One Assistant for Claude Code, Codex & Gemini CLI";
            homepage = "https://github.com/farion1231/cc-switch";
            license = licenses.mit;
            platforms = platforms.linux;
            mainProgram = "cc-switch";
          };
        };
    in
    {
      packages = forAllSystems (system: {
        default = mkPackage (import nixpkgs { inherit system; });
        cc-switch = mkPackage (import nixpkgs { inherit system; });
      });

      overlays.default = final: prev: {
        cc-switch = self.packages.${prev.system}.cc-switch or self.packages.${prev.system}.default;
      };
    };
}
