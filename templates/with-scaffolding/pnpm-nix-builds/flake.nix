{
  description = "Barebones pnpm project with offline Nix builds";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {self, ...} @ inputs: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system: let
          pkgs = import inputs.nixpkgs {inherit system;};
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
        in
          f {
            inherit pkgs system nodejs pnpm pnpmDeps pnpmStoreName version;
          }
      );
  in {
    # ─────────────────────────────────────────────
    # Dev shell
    # ─────────────────────────────────────────────
    devShells = forEachSupportedSystem (
      {
        pkgs,
        nodejs,
        pnpm,
        pnpmDeps,
        ...
      }: {
        default = pkgs.mkShellNoCC {
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
            echo "nixpkgs revision: ${inputs.nixpkgs.rev}"
            echo "pnpm version: $(pnpm --version)"
            echo "node version: $(node --version)"
            echo ""
          '';
        };
      }
    );

    # ─────────────────────────────────────────────
    # Build
    #
    #  Notes:
    #   - pnpm.configHook wires the pre-fetched store into pnpm.
    #   - The build runs entirely offline once pnpmDeps hash is fixed.
    # ─────────────────────────────────────────────
    packages = forEachSupportedSystem (
      {
        pkgs,
        nodejs,
        pnpm,
        pnpmDeps,
        pnpmStoreName,
        version,
        ...
      }: {
        default = pkgs.stdenv.mkDerivation {
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
  };
}
