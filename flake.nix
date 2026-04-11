{
  description = "Real Life Infrastructure — NixOS Server Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosModules = {
      base = import ./modules/base.nix;
      docker = import ./modules/docker.nix;
      traefik = import ./modules/traefik.nix;
    };

    nixosConfigurations = {
      timo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/timo/hardware-configuration.nix
          ./hosts/timo/default.nix
          ./modules/base.nix
          ./modules/docker.nix
          ./modules/traefik.nix
        ];
      };
    };
  };
}
