{
  description = "A Collection of Nix Flake Templates";

  outputs = {...}: {
    templates = {
      # Flake-only templates
      bun-flake-only = {
        path = ./templates/flake-only/bun;
        description = "A basic bun flake for development";
      };
      pnpm-flake-only = {
        path = ./templates/flake-only/pnpm;
        description = "A basic pnpm & node flake for development";
      };
      python-pip-flake-only = {
        path = ./templates/flake-only/python-pip;
        description = "A basic python development environment with pip and venv";
      };
      Rust-stable-flake-only = {
        path = ./templates/flake-only/rust-stable;
        description = "A flake for Rust development based on the stable toolchain";
      };
      ocaml-flake-only = {
        path = ./templates/flake-only/ocaml;
        description = "A basic ocaml flake for development";
      };
      # Templates that include project scaffolding
      pnpm-nix-builds-with-scaffolding = {
        path = ./templates/with-scaffolding/pnpm-nix-builds;
        description = "A simple pnpm & node project template that uses nix for npm dependencies and builds";
      };
    };
  };
}
