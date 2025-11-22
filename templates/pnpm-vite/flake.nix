{
  description = "PNPM + Vite project with offline Nix builds";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    pnpm2nix.url = "github:nix-community/pnpm2nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, pnpm2nix, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      	let
			# Import nixpkgs for this system
			pkgs = import nixpkgs { inherit system; };

			# Generates node-deps.nix which statically stores tarballs for all
			# of the dependencies fetched with pnpm for this flake.
			nodeDeps = pnpm2nix.mkPnpmPackage {
				inherit pkgs;
				# The entire project is passed as the src so pnpm2nix can read
				# pnpm-lock.yaml and resolve each dependency tarball.
				src = ./.;
			};

			# --- Inline stale-check logic --------------------------
			checkNodeDeps =
				let
					lockHash = builtins.hashFile "sha256" ./pnpm-lock.yaml;

					depsInfo =
						if builtins.pathExists ./node-deps.nix
						then import ./node-deps.nix
						else { lockHash = ""; };
				in {
					inherit lockHash;
					stale = lockHash != depsInfo.lockHash;
				};
			# --------------------------------------------------------

			# Script for regenerating deps
			genDepsScript = pkgs.writeShellScriptBin "gen-deps" ''
				set -e
				echo "Regenerating node-deps.nix..."

				tmp="$(mktemp)"
				pnpm2nix > "$tmp"

				# Prepend the lockHash
				{
					echo "{ lockHash = \"$(nix hash file ./pnpm-lock.yaml)\"; }"
					cat "$tmp"
				} > node-deps.nix

				rm "$tmp"
				echo "Done."
			'';
      	in {

			# ─────────────────────────────────────────────
			# Dev shell
			# ─────────────────────────────────────────────
			devShell = pkgs.mkShell {
				buildInputs = [
					pkgs.nodejs_24
					pkgs.pnpm
					genDepsScript
				];

				# check if node-deps.nix is stale relative to pnpm.lock, an if so, warn
				# the user and suggest running the gen-deps script to update node-deps.nix
				shellHook = ''
					if [ "${builtins.toString checkNodeDeps.stale}" = "true" ]; then
						echo "	WARNING: node-deps.nix is stale compared to pnpm-lock.yaml"
									echo " 	To update node-deps.nix to reflect pnpm-lock.yaml:"
						echo "	Run: gen-deps"
					fi
					'';

				# This directs PNPM’s global store into a per-shell temporary directory.
				# Without this, PNPM attempts to write in /homeless-shelter when run
				# inside Nix’s environment. This does NOT affect project reproducibility.
				PnpmStoreDir = "${nodeDeps.pnpmStore}";
			};

			# ─────────────────────────────────────────────
			# Build
			#
			#  Notes:
			#   - PNPM cannot access the network in pure builds.
			#   - Therefore, nodeDeps.pnpmStore MUST contain all resolved deps.
			# 	- The build uses "pnpm install --offline" for guaranteed reproducibility.
			# ─────────────────────────────────────────────
			packages.default = pkgs.stdenv.mkDerivation {
				name = "vite-build";
				src = ./.;

				buildInputs = [
					pkgs.nodejs_24
					pkgs.pnpm
				];

				# offline build using the prefetched store
				buildPhase = ''
					if [ "${builtins.toString checkNodeDeps.stale}" = "true" ]; then
						echo "	WARNING: node-deps.nix is stale compared to pnpm-lock.yaml"
						echo " 	To update node-deps.nix to reflect pnpm-lock.yaml:"
						echo "	Run: gen-deps"
					fi

					echo ">>> Using offline pnpm store at: ${nodeDeps.pnpmStore}"
					export PNPM_STORE_PATH="${nodeDeps.pnpmStore}"

					# Install dependencies without network access.
					pnpm install --offline

					# Build the Vite production bundle.
					pnpm run build
				'';

				installPhase = ''
					mkdir -p $out
					cp -r dist/* $out/
				'';
			};
      	}
    );
}
