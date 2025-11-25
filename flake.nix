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
    };
  };
}
