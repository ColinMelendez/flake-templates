{
  description = "A basic pnpm flake setup for development";

  # inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # flakehub based unstable Nixpkgs
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # unstable Nixpkgs

  outputs = {self, ...} @ inputs: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import inputs.nixpkgs {inherit system;};
          }
      );
  in {
    devShells = forEachSupportedSystem (
      {pkgs, ...}: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            pnpm
            nodejs_24
          ];
        };
      }
    );
  };
}
