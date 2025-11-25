{
  description = "Barebones pnpm project with offline Nix builds";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    # self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        nodejs = pkgs.nodejs_24;
        pnpm = pkgs.pnpm;

        # stable identifier pair for the cache store of the pnpmDeps result
        # change this to something meaningful for the project.
        pnpmStoreName = "pnpm-store-name";
        version = "0.0.0";

        # Pre-fetch all dependencies declared in pnpm-lock.yaml so builds stay offline.
        pnpmDeps = pnpm.fetchDeps {
          inherit pnpmStoreName version;
          src = ./.;
          pnpmLock = ./pnpm-lock.yaml;
          fetcherVersion = 2;
          # this hash needs to be updated whenever pnpm-lock.yaml changes
          hash = "sha256-/r3Fi7Gbl3k1cFCuyj67zA8GvITkcOo3qSTFMWFQYcs=";
        };
      in {
        # ─────────────────────────────────────────────
        # Dev shell
        # ─────────────────────────────────────────────
        devShells.default = pkgs.mkShell {
          packages = [
            nodejs
            pnpm
          ];
          nativeBuildInputs = [
            pnpm.configHook
          ];
          inherit pnpmDeps;
          pnpmRoot = ".";
          shellHook = ''
            echo ""
            echo "Environment:"
            echo "nixpkgs revision: ${nixpkgs.rev}"
            echo "pnpm version: $(pnpm --version)"
            echo "node version: $(node --version)"
            echo ""
          '';
        };

        # ─────────────────────────────────────────────
        # Build
        #
        #  Notes:
        #   - pnpm.configHook wires the pre-fetched store into pnpm.
        #   - The build runs entirely offline once pnpmDeps hash is fixed.
        # ─────────────────────────────────────────────
        packages.default = pkgs.stdenv.mkDerivation {
          inherit pnpmStoreName version;
          src = ./.;

          nativeBuildInputs = [
            nodejs
            pnpm.configHook
          ];

          inherit pnpmDeps;
          pnpmRoot = ".";

          buildPhase = ''
            runHook preBuild
            pnpm run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r dist/* $out/
            runHook postInstall
          '';
        };
      }
    );
}
