# Javascript

Revision: Nov 22, 2025

1. Introduction
2. Getting unstuck / finding code examples
3. General principles
4. Javascript packages inside nixpkgs
5. Tool-specific instructions
6. Outside Nixpkgs

## Introduction

This contains instructions on how to package JavaScript applications.

The various tools available will be listed in the tools-overview. Some general principles for packaging will follow. Finally, some tool-specific instructions will be given.

## Getting unstuck / finding code examples

If you find you are lacking inspiration for packaging JavaScript applications, the links below might prove useful. Searching online for prior art can be helpful if you are running into solved problems.

### Github

Searching Nix files for yarnConfigHook: <https://github.com/search?q=yarnConfigHook+language%3ANix&type=code>

Searching just flake.nix files for yarnConfigHook: <https://github.com/search?q=yarnConfigHook+path%3A**%2Fflake.nix&type=code>

### Gitlab

Searching Nix files for yarnConfigHook: <https://gitlab.com/search?scope=blobs&search=yarnConfigHook+extension%3Anix>

Searching just flake.nix files for yarnConfigHook: <https://gitlab.com/search?scope=blobs&search=yarnConfigHook+filename%3Aflake.nix>

## General principles

The following principles are given in order of importance with potential exceptions.

### Try to use the same node version used upstream

It is often not documented which node version is used upstream, but if it is, try to use the same version when packaging.

This can be a problem if upstream is using the latest and greatest and you are trying to use an earlier version of node. Some cryptic errors regarding V8 may appear.

### Try to respect the package manager originally used by upstream (and use the upstream lock file)

A lock file (package-lock.json, yarn.lock…) is supposed to make reproducible installations of node_modules for each tool.

Guidelines of package managers, recommend to commit those lock files to the repos. If a particular lock file is present, it is a strong indication of which package manager is used upstream.

It’s better to try to use a Nix tool that understands the lock file. Using a different tool might give you a hard-to-understand error because different packages have been installed. An example of problems that could arise can be found here. Upstream use npm, but this is an attempt to package it with yarn2nix (that uses yarn.lock).

Using a different tool forces you to commit a lock file to the repository. These files are fairly large, so when packaging for nixpkgs, this approach does not scale well.

Exceptions to this rule are:

- When you encounter one of the bugs from a Nix tool. In each of the tool-specific instructions, known problems will be detailed. If you have a problem with a particular tool, then it’s best to try another tool, even if this means you will have to re-create a lock file and commit it to Nixpkgs. In general yarn2nix has fewer known problems, and so a simple search in Nixpkgs will reveal many yarn.lock files committed.

- Some lock files contain particular version of a package that has been pulled off npm for some reason. In that case, you can recreate upstream lock (by removing the original and npm install, yarn, …) and commit this to nixpkgs.

- The only tool that supports workspaces (a feature of npm that helps manage sub-directories with different package.json from a single top level package.json) is yarn2nix. If upstream has workspaces you should try yarn2nix.

### Try to use upstream package.json

Exceptions to this rule are:

- Sometimes the upstream repo assumes some dependencies should be installed globally. In that case, you can add them manually to the upstream package.json (`yarn add xxx` or `npm install xxx`, …). Dependencies that are installed locally can be executed with npx for CLI tools (e.g. `npx postcss ...`, this is how you can call those dependencies in the phases).

- Sometimes there is a version conflict between some dependency requirements. In that case you can fix a version by removing the ^.

- Sometimes the script defined in the package.json does not work as is. Some scripts for example use CLI tools that might not be available, or cd in directory with a different package.json (for workspaces notably). In that case, it’s perfectly fine to look at what the particular script is doing and break this down in the phases. In the build script you can see build:* calling in turns several other build scripts like build:ui or build:server. If one of those fails, you can try to separate those into,

```shell
yarn build:ui
yarn build:server
# OR
npm run build:ui
npm run build:server
```

when you need to override a package.json. It’s nice to use the one from the upstream source and do some explicit override. Here is an example:

```nix
{
  patchedPackageJSON = final.runCommand "package.json" { } ''
    ${jq}/bin/jq '.version = "0.4.0" |
      .devDependencies."@jsdoc/cli" = "^0.2.5"
      ${sonar-src}/package.json > $out
  '';
}
```

You will still need to commit the modified version of the lock files, but at least the overrides are explicit for everyone to see.

### Using node_modules directly

Each tool has an abstraction to just build the node_modules (dependencies) directory. You can always use the `stdenv.mkDerivation` with the node_modules to build the package (symlink the node_modules directory and then use the package build command). The node_modules abstraction can be also used to build some web framework frontends. For an example of this see how plausible is built. mkYarnModules to make the derivation containing node_modules. Then when building the frontend you can just symlink the node_modules directory.

## Javascript packages inside nixpkgs

The `pkgs/development/node-packages` folder contains a generated collection of npm packages that can be installed with the Nix package manager.

As a rule of thumb, the package set should only provide end-user software packages, such as command-line utilities. Libraries should only be added to the package set if there is a non-npm package that requires it.

When it is desired to use npm libraries in a development project, use the node2nix generator directly on the package.json configuration file of the project.

The package set provides support for the official stable Node.js versions. The latest stable LTS release in nodePackages, as well as the latest stable current release in nodePackages_latest.

If your package uses native addons, you need to examine what kind of native build system it uses. Here are some examples:

- node-gyp

- node-gyp-builder

- node-pre-gyp

After you have identified the correct system, you need to override your package expression while adding in build system as a build input. For example, dat requires node-gyp-build, so we override its expression in `pkgs/development/node-packages/overrides.nix`:

```nix
{
  dat = prev.dat.override (oldAttrs: {
    buildInputs = [
      final.node-gyp-build
      pkgs.libtool
      pkgs.autoconf
      pkgs.automake
    ];
    meta = oldAttrs.meta // {
      broken = since "12";
    };
  });
}
```

### Adding and updating JavaScript packages in Nixpkgs

To add a package from npm to Nixpkgs:

1. Modify pkgs/development/node-packages/node-packages.json to add, update or remove package entries to have it included in nodePackages and nodePackages_latest.

2. Run the script:

    ```shell
    ./pkgs/development/node-packages/generate.sh
    ```

3. Build your new package to test your changes:

    ```shell
    nix-build -A nodePackages.<new-or-updated-package>
    ```

    To build against the latest stable Current Node.js version (e.g. 18.x):

    ```shell
    nix-build -A nodePackages_latest.<new-or-updated-package>
    ```

    If the package doesn’t build, you may need to add an override as explained above.

4. If the package’s name doesn’t match any of the executables it provides, add an entry in `pkgs/development/node-packages/main-programs.nix`. This will be the case for all scoped packages, e.g., @angular/cli.

5. Add and commit all modified and generated files.

For more information about the generation process, consult the README.md file of the node2nix tool.

To update npm packages in Nixpkgs, run the same generate.sh script:

```shell
./pkgs/development/node-packages/generate.sh
```

#### Git protocol error

Some packages may have Git dependencies from GitHub specified with git://. GitHub has disabled unencrypted Git connections, so you may see the following error when running the generate script:

The unauthenticated git protocol on port 9418 is no longer supported
Use the following Git configuration to resolve the issue:

git config --global url."<https://github.com/".insteadOf> git://github.com/

## Tool-specific instructions

### buildNpmPackage

`buildNpmPackage` allows you to package npm-based projects in Nixpkgs without the use of an auto-generated dependencies file (as used in node2nix). It works by utilizing npm’s cache functionality – creating a reproducible cache that contains the dependencies of a project, and pointing npm to it.

Here’s an example:

```nix
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "flood";
  version = "4.7.0";

  src = fetchFromGitHub {
    owner = "jesec";
    repo = "flood";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BR+ZGkBBfd0dSQqAvujsbgsEPFYw/ThrylxUbOksYxM=";
  };

  npmDepsHash = "sha256-tuEfyePwlOy2/mOPdXbqJskO6IowvAP4DWg8xSZwbJw=";

  # The prepack script runs the build script, which we'd rather do in the build phase.
  npmPackFlags = [ "--ignore-scripts" ];

  NODE_OPTIONS = "--openssl-legacy-provider";

  meta = {
    description = "Modern web UI for various torrent clients with a Node.js backend and React frontend";
    homepage = "<https://flood.js.org>";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ winter ];
  };
})
```

In the default installPhase set by `buildNpmPackage`, it uses `npm pack --json --dry-run` to decide what files to install in `$out/lib/node_modules/$name/`, where `$name` is the name string defined in the package’s package.json. Additionally, the `bin` and `man` keys in the source’s package.json are used to decide what binaries and manpages are supposed to be installed. If these are not defined, `npm pack` may miss some files, and no binaries will be produced.

#### Arguments

- npmDepsHash: The output hash of the dependencies for this project. Can be calculated in advance with prefetch-npm-deps.

- makeCacheWritable: Whether to make the cache writable prior to installing dependencies. Don’t set this unless npm tries to write to the cache directory, as it can slow down the build.

- npmBuildScript: The script to run to build the project. Defaults to "build".

- npmWorkspace: The workspace directory within the project to build and install.

- dontNpmBuild: Option to disable running the build script. Set to true if the package does not have a build script. Defaults to false. Alternatively, setting buildPhase explicitly also disables this.

- dontNpmInstall: Option to disable running npm install. Defaults to false. Alternatively, setting installPhase explicitly also disables this.

- npmFlags: Flags to pass to all npm commands.

- npmInstallFlags: Flags to pass to npm ci.

- npmBuildFlags: Flags to pass to npm run ${npmBuildScript}.

- npmPackFlags: Flags to pass to npm pack.

- npmPruneFlags: Flags to pass to npm prune. Defaults to the value of npmInstallFlags.

- makeWrapperArgs: Flags to pass to makeWrapper, added to executable calling the generated .js with node as an interpreter. These scripts are defined in package.json.

- nodejs: The nodejs package to build against, using the corresponding npm shipped with that version of node. Defaults to pkgs.nodejs.

- npmDeps: The dependencies used to build the npm package. Especially useful to not have to recompute workspace dependencies.

#### prefetch-npm-deps

prefetch-npm-deps is a Nixpkgs package that calculates the hash of the dependencies of an npm project ahead of time.

```shell
ls
package.json package-lock.json index.js
> prefetch-npm-deps package-lock.json
...
sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
```

#### fetchNpmDeps

fetchNpmDeps is a Nix function that requires the following mandatory arguments:

- src: A directory / tarball with package-lock.json file

- hash: The output hash of the node dependencies defined in package-lock.json.

It returns a derivation with all package-lock.json dependencies downloaded into $out/, usable as an npm cache.

#### importNpmLock

This function replaces the npm dependency references in package.json and package-lock.json with paths to the Nix store. How each dependency is fetched can be customized with the fetcherOpts argument.

This is a simpler and more convenient alternative to fetchNpmDeps for managing npm dependencies in Nixpkgs. There is no need to specify a hash, since it relies entirely on the integrity hashes already present in the package-lock.json file.

#### Inputs

- npmRoot: Path to package directory containing the source tree. If this is omitted, the package and packageLock arguments must be specified instead.

- package: Parsed contents of package.json

- packageLock: Parsed contents of package-lock.json

- pname: Package name

- version: Package version

- fetcherOpts: An attribute set of arguments forwarded to the underlying fetcher.

It returns a derivation with a patched package.json & package-lock.json with all dependencies resolved to Nix store paths.

> Note
> npmHooks.npmConfigHook cannot be used with importNpmLock. Use importNpmLock.npmConfigHook instead.

#### Example 374. pkgs.importNpmLock usage example

```nix
{ buildNpmPackage, importNpmLock }:

buildNpmPackage {
  pname = "hello";
  version = "0.1.0";
  src = ./.;

  npmDeps = importNpmLock { npmRoot = ./.; };

  npmConfigHook = importNpmLock.npmConfigHook;
}
```

#### Example 375. pkgs.importNpmLock usage example with fetcherOpts

importNpmLock uses the following fetchers:

- pkgs.fetchurl for http(s) dependencies

- fetchGit for git dependencies

It is possible to provide additional arguments to individual fetchers as needed:

```nix
{ buildNpmPackage, importNpmLock }:

buildNpmPackage {
  pname = "hello";
  version = "0.1.0";
  src = ./.;

  npmDeps = importNpmLock {
    npmRoot = ./.;
    fetcherOpts = {
      # Pass 'curlOptsList' to 'pkgs.fetchurl' while fetching 'axios'
      "node_modules/axios" = {
        curlOptsList = [ "--verbose" ];
      };
    };
  };

  npmConfigHook = importNpmLock.npmConfigHook;
}
```

### importNpmLock.buildNodeModules

importNpmLock.buildNodeModules returns a derivation with a pre-built node_modules directory, as imported by importNpmLock.

This is to be used together with importNpmLock.hooks.linkNodeModulesHook to facilitate nix-shell/nix develop based development workflows.

It accepts an argument with the following attributes:

- npmRoot (Path; optional)
    Path to package directory containing the source tree. If not specified, the package and packageLock arguments must both be specified.

- package (Attrset; optional)
    Parsed contents of package.json, as returned by lib.importJSON ./my-package.json. If not specified, the package.json in npmRoot is used.

- packageLock (Attrset; optional)
    Parsed contents of package-lock.json, as returned lib.importJSON ./my-package-lock.json. If not specified, the package-lock.json in npmRoot is used.

- derivationArgs (mkDerivation attrset; optional)
    Arguments passed to stdenv.mkDerivation

For example:

```nix
pkgs.mkShell {
  packages = [
    importNpmLock.hooks.linkNodeModulesHook
    nodejs
  ];

  npmDeps = importNpmLock.buildNodeModules {
    npmRoot = ./.;
    inherit nodejs;
  };
}
```

will create a development shell where a node_modules directory is created & packages symlinked to the Nix store when activated.

> Note
> Commands like npm install & npm add that write packages & executables need to be used with --package-lock-only.
> This means npm installs dependencies by writing into package-lock.json without modifying the node_modules folder. Installation happens through reloading the devShell. This might be best practice since it gives the nix shell virtually exclusive ownership over your node_modules folder.
> It’s recommended to set package-lock-only = true in your project-local .npmrc.

### corepack

This package puts the corepack wrappers for pnpm and yarn in your PATH, and they will honor the packageManager setting in the package.json.

### node2nix

#### Preparation

You will need to generate a Nix expression for the dependencies. Don’t forget the -l package-lock.json if there is a lock file. Most probably you will need the --development to include the devDependencies

So the command will most likely be:

`node2nix --development -l package-lock.json`
See node2nix docs for more info.

#### Pitfalls

If upstream package.json does not have a “version” attribute, node2nix will crash. You will need to add it like shown in the package.json section.

node2nix has some bugs related to working with lock files from npm distributed with nodejs_16.

node2nix does not like missing packages from npm. If you see something like Cannot resolve version: vue-loader-v16@undefined then you might want to try another tool. The package might have been pulled off of npm.

### pnpm

Pnpm is available as the top-level package pnpm. Additionally, there are variants pinned to certain major versions, like pnpm_8 and pnpm_9, which support different sets of lock file versions.

When packaging an application that includes a pnpm-lock.yaml, you need to fetch the pnpm store for that project using a fixed-output-derivation. The functions pnpm_8.fetchDeps and pnpm_9.fetchDeps can create this pnpm store derivation. In conjunction, the setup hooks pnpm_8.configHook and pnpm_9.configHook will prepare the build environment to install the pre-fetched dependencies store. Here is an example for a package that contains package.json and a pnpm-lock.yaml files using the above pnpm_ attributes:

```nix
{
  stdenv,
  nodejs,
  # This is pinned as { pnpm = pnpm_9; }
  pnpm,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "foo";
  version = "0-unstable-1980-01-01";

  src = {
    #...
  };

  nativeBuildInputs = [
    nodejs
    pnpm.configHook
  ];

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    hash = "...";
  };
})
```

>NOTE: It is highly recommended to use a pinned version of pnpm (i.e., pnpm_8 or pnpm_9), to increase future reproducibility. It might also be required to use an older version if the package needs support for a certain lock file version.

In case you are patching package.json or pnpm-lock.yaml, make sure to pass finalAttrs.patches to the function as well (i.e., inherit (finalAttrs) patches.

`pnpm.configHook` supports adding additional pnpm install flags via `pnpmInstallFlags` which can be set to a Nix string array:

```nix
{ pnpm }:

stdenv.mkDerivation (finalAttrs: {
  pname = "foo";
  version = "0-unstable-1980-01-01";

  src = {
    # ...
  };

  pnpmInstallFlags = [ "--shamefully-hoist" ];

  pnpmDeps = pnpm.fetchDeps { inherit (finalAttrs) pnpmInstallFlags; };
})
```

### Dealing with sourceRoot

If the pnpm project is in a subdirectory, you can just define sourceRoot or setSourceRoot for fetchDeps. If sourceRoot is different between the parent derivation and fetchDeps, you will have to set pnpmRoot to effectively be the same location as it is in fetchDeps.

Assuming the following directory structure, we can define sourceRoot and pnpmRoot as follows:

```text
.
├── frontend
│   ├── ...
│   ├── package.json
│   └── pnpm-lock.yaml
└── ...
```

```nix
{
  # ...
  pnpmDeps = pnpm.fetchDeps {
    # ...
    sourceRoot = "${finalAttrs.src.name}/frontend";
  };

  # by default the working directory is the extracted source
  pnpmRoot = "frontend";
}
```

### PNPM Workspaces

If you need to use a PNPM workspace for your project, then set `pnpmWorkspaces = [ "<workspace project name 1>" "<workspace project name 2>" ]`, etc, in your `pnpm.fetchDeps` call, which will make PNPM only install dependencies for those workspace packages.

For example:

```nix
{
  # ...
  pnpmWorkspaces = [ "@astrojs/language-server" ];
  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) pnpmWorkspaces;
    #...
  };
}
```

The above would make `pnpm.fetchDeps` call only install dependencies for the `@astrojs/language-server` workspace package. Note that you do not need to set `sourceRoot` to make this work.

Usually, in such cases, you’d want to use `pnpm --filter=<pnpm workspace name>` build to build your project, as `npmHooks.npmBuildHook` probably won’t work. A buildPhase based on the following example will probably fit most workspace projects:

```nix
{
  buildPhase = ''
    runHook preBuild

    pnpm --filter=@astrojs/language-server build

    runHook postBuild
  '';
}
```

#### Additional PNPM Commands and settings

If you require setting an additional PNPM configuration setting (such as dedupe-peer-dependents or similar), set `prePnpmInstall` to the right commands to run. For example:

```nix
{
  prePnpmInstall = ''
    pnpm config set dedupe-peer-dependents false
  '';
  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs) prePnpmInstall;
    # ...
  };
}
```

In this example, `prePnpmInstall` will be run by both `pnpm.configHook` and by the `pnpm.fetchDeps` builder.

#### PNPM fetcherVersion

This is the version of the output of `pnpm.fetchDeps`, if you haven’t set it already, you can use 1 with your current hash:

```nix
{
  # ...
  pnpmDeps = pnpm.fetchDeps {
    # ...
    fetcherVersion = 1;
    hash = "..."; # you can use your already set hash here
  };
}
```

After upgrading to a newer `fetcherVersion`, you need to regenerate the hash:

```nix
{
  # ...
  pnpmDeps = pnpm.fetchDeps {
    # ...
    fetcherVersion = 2;
    hash = "..."; # clear this hash and generate a new one
  };
}
```

This variable ensures that we can make changes to the output of `pnpm.fetchDeps` without breaking existing hashes. Changes can include workarounds or bug fixes to existing PNPM issues.

#### Version history

1. Initial version, nothing special

2. Ensure consistent permissions

## Outside Nixpkgs

There are some other tools available, which are written in the Nix language. These can’t be used inside Nixpkgs because they require Import From Derivation, which is not allowed in Nixpkgs.

### Other Pitfalls

There are some problems with npm v7.

#### nix-npm-buildpackage

nix-npm-buildpackage aims at building node_modules without code generation. It hasn’t reached v1 yet, the API might change. It supports both package-lock.json and yarn.lock.
