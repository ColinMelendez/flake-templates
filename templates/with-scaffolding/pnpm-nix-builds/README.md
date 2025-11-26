# pnpm + Nix template

This template gives you a minimal pnpm workspace with support for:

- fetching pnpm dependencies up front via `pnpm.fetchDeps` so both `nix develop` and `nix build` work completely offline
- running project builds through `pnpm run build` inside a hermetic Nix derivation

The goal is to provide the lightest possible starting point for JS development with pnpm while taking advantage of Nix for end-to-end build and environment support as much as possible.

## contents

- [Quick Start](#quick-start)
- [Template Outline](#template-outline)
- [Typical Workflow](#typical-workflow)
- [Keeping pnpm deps in-sync](#keeping-pnpm-deps-in-sync)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

Ensure that Nix is installed on your machine, and that flakes are enabled. Development and testing of these templates was done with Determinate Nix.

In the directory you wish to initialize the template in, run:

```bash
nix flake init -t "github:colinmelendez/flake-templates#pnpm"
```

You can then start up the Nix development shell with:

```bash
nix develop
# -- or --
nix develop -c $SHELL   # to impurely bring your non-nix shell into the dev shell
```

Or you can use Direnv to enter the shell automatically.

Inside the dev shell, `pnpm` is configured to use the pre-fetched dependency store, so `pnpm install`, `pnpm run <script>`, etc., never touch the network.

You may proceed to use your normal pnpm workflow in the shell. The only extra complication is that you need to keep the flakes pnpmDeps hash up to date as
you make changes that affect the lockfile over time. [See Troubleshooting.](#troubleshooting)

The template assumes you have access to bash and git on your machine outside of this flake.

---

## Template Outline

- `flake.nix` – wires nixpkgs, flake-utils, and sets up:
  - `devShells.default`: `mkShell` with `nodejs`, `pnpm`, and `pnpm.configHook`
  - `packages.default`: simple derivation that runs `pnpm run build` then copies `dist/` to `$out`
- `pnpm-lock.yaml` – source of truth for dependencies; used by `pnpm.fetchDeps`
- `package.json` – currently empty; you should generally drive project-related configuration from here (dependencies, scripts, etc.) and not lean on the flake for things that are sufficiently covered elsewhere.

---

## Typical workflow

1. **Develop**

   ```bash
   nix develop
   pnpm install
   pnpm run dev   # or whatever scripts you add
   ```

2. **Build**

   ```bash
   nix build       # runs pnpm run build in a pure sandbox
   ls result       # contains whatever was produced in dist/
   ```

3. **Run checks**
   Extend `pnpm run test`, `pnpm run lint`, etc., and optionally expose them via `checks.${system}` or additional `packages` if you want `nix flake check`/`nix build .#lint`.

---

## Keeping pnpm deps in-sync

Any time `pnpm-lock.yaml` changes, the `pnpm.fetchDeps` hash in `flake.nix` must be updated.

- Run `nix build` (or `nix develop`). The first attempt will fail with a message like:

  ```text
  got:    sha256-<actual-hash-of-pnpm-lock>
  wanted: sha256-<current-hash-from-flake>
  ```

- Paste the hash reported as "got:" into `flake.nix` under the hash attribute of `pnpmDeps` like so:

  ```nix
    # Pre-fetch all dependencies declared in pnpm-lock.yaml so builds stay offline.
    pnpmDeps = pnpm.fetchDeps {
        inherit pname version;
        src = ./.;
        pnpmLock = ./pnpm-lock.yaml;
        fetcherVersion = 2;
        # this hash needs to be updated whenever pnpm-lock.yaml changes
        hash = "sha256-<hash-goes-here>";
    };
  ```

- Re-run the build or develop command.
- builds/dev shells will now successfully reuse the cached store.

This is the standard Nix fixed-output workflow and guarantees hermetic, cacheable installs.

This process also works for packages that have built sub-deps. Simply approve the builds as you normally would with pnpm.

---

## Troubleshooting

- seeing **`Hash mismatch`** when you try to start the shell means the lockfile changed. Update the hash in `flake.nix` as described above.
- **Missing `node_modules` outside the shell:** all installs happen through the Nix-managed store. Enter `nix develop` before running `pnpm`.
- **Need a different Node.js or pnpm version:** swap `nodejs = pkgs.nodejs_XX;` or `pnpm = pkgs.pnpm_X;` in `flake.nix`.

## Suggestions for future work

- This template does not provide a way to automatically update the flake's pnpmDeps hash when dependencies are added or removed, relying on manually updating the hash. This could be easily improved with a small script that you run after modifying the lockfile.
