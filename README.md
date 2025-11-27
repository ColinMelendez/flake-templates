# Flake Templates

This is a collection of Nix flake templates to quickly scaffold new projects or easily add simple flakes to existing projects.

The templates come in two flavors:

- **With Scaffolding** - These templates include the basic scaffolding for a project beyond just defining a flake. THey should only be used to seed new projects in empty directories.

- **Flake Only** - These templates contain only a flake and as such are a good option for adding to existing projects or when some custom scaffolding is desired.

## Quick Start

Ensure you have Nix installed on your system, and flakes are enabled. For information on setting up Nix, I recommend [Zero-to-Nix](https://zero-to-nix.com/)

To browse the templates from this repository in your terminal, run:

```shell
nix flake show "github:colinmelendez/flake-templates"
```

To initialize a template in your current directory:

```shell
nix flake init --template "github:colinmelendez/flake-templates#<template-name>"
```

For example:

```shell
nix flake init --template "github:colinmelendez/flake-templates#pnpm"
```

You can then enter the nix development shell with:

```shell
nix develop
```

## templates

### Flake Only

- pnpm

### With Scaffolding

- pnpm-nix-builds

## Other

- All templates do not include git in the flake, assuming that the user has git installed globally on their system.

- Testing and development of these templates was done using Determinate Systems Nix, and generally follows the patterns observed in their flakes. This should not impact their viability when used with standard Nix.

- To initialize a flake template in a target directory, you can use:

    ```shell
    nix flake new --template "github:colinmelendez/flake-templates#<template-name>" "<target-directory>"
    ```