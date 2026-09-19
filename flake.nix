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

      # Elis eigener Server. Ohne traefik.nix: Eli hat ihren eigenen
      # Caddy als Container, mit Zertifikaten, die seit Monaten laufen.
      # Auf Traefik umzustellen waere eine zweite Aenderung waehrend
      # eines Umzugs; das kommt spaeter, wenn ueberhaupt.
      eli = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/eli/hardware-configuration.nix
          ./hosts/eli/default.nix
          ./hosts/eli/dienste.nix
          ./modules/base.nix
          ./modules/docker.nix
        ];
      };
    };
  };
}
