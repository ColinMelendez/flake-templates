{
  description = "A Collection of Nix Flake Templates";

  outputs = {
    # self,
    ...
  }: {
    templates = {
      pnpm-vite = {
        path = ./templates/pnpm;
        description = "A barebones javascript setup with pnpm";
      };
    };
  };
}
