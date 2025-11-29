{
  description = "A Collection of Nix Flake Templates";

  outputs = {...}: {
    templates = {
      # Flake-only templates
      pnpm-flake-only = {
        path = ./templates/flake-only/pnpm;
        description = "A basic pnpm & node flake for development";
      };
      bun-flake-only = {
        path = ./templates/flake-only/bun;
        description = "A basic bun flake for development";
      };
      Rust-stable-flake-only = {
        path = ./templates/flake-only/rust-stable;
        description = "A flake for Rust development with based on the stable toolchain";
      };
      # Templates that include project scaffolding
      pnpm-nix-builds-with-scaffolding = {
        path = ./templates/with-scaffolding/pnpm-nix-builds;
        description = "A simple pnpm & node project template that uses nix for npm dependencies and builds";
      };
    };
  };
}
