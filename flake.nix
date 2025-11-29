{
  description = "A Collection of Nix Flake Templates";

  outputs = {...}: {
    templates = {
      pnpm-nix-builds-with-scaffolding = {
        path = ./templates/with-scaffolding/pnpm-nix-builds;
        description = "A simple pnpm & node setup that uses nix for npm dependencies and builds";
      };
      pnpm-flake-only = {
        path = ./templates/flake-only/pnpm;
        description = "A basic pnpm & node flake for development";
      };
      bun-flake-only = {
        path = ./templates/flake-only/bun;
        description = "A basic bun flake for development";
      };
    };
  };
}
