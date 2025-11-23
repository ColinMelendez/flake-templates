{
  description = "A Collection of Nix Flake Templates";

  outputs = {
    # self,
    ...
  }: {
    templates = {
      pnpm-vite = {
        path = ./templates/pnpm-vite;
        description = "A simple typescript setup with pnpm, vite, vitest, and eslint set up";
      };
    };
  };
}
