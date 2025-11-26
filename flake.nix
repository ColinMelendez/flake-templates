{
  description = "A Collection of Nix Flake Templates";

  outputs = {
    # self,
    ...
  }: {
    templates = {
      pnpm-vite = {
        path = ./templates/pnpm-with-nix-builds;
        description = "A barebones javascript setup with pnpm that uses nix for npm dependencies";
      };
      pnpm-flake-only = {
        path = ./templates/flake-only/pnpm;
        description = "A basic pnpm & node flake for development";
      };
    };
  };
}
