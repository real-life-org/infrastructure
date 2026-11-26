{
  description = "Real Life Infrastructure — NixOS Server Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Nur fuer timo, voruebergehend: dort laufen traefik:v3.3 und
    # containrrr/watchtower, deren Docker-Clients aeltere API-Versionen
    # sprechen, als Docker 29 (nixos-26.05) annimmt. Mit 26.05 verloeren
    # beide den Zugang zu Docker und alle Seiten hinter Traefik fielen aus.
    # timo ist zurzeit nicht erreichbar, also nicht testbar. Sobald er es
    # ist: Traefik und Watchtower auf Docker-29-faehige Fassungen heben,
    # timo auf nixpkgs umstellen, diesen Eingang entfernen.
    nixpkgs-2411.url = "github:NixOS/nixpkgs/nixos-24.11";
    # Nur fuer einzelne Pakete, die GitHub oder andere Dienste in neuer
    # Version verlangen (GitHub-Runner: Mindestversion seit Februar 2026).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-2411, nixpkgs-unstable, ... }: {
    nixosModules = {
      base = import ./modules/base.nix;
      docker = import ./modules/docker.nix;
      watchtower = import ./modules/watchtower.nix;
      traefik = import ./modules/traefik.nix;
    };

    nixosConfigurations = {
      timo = nixpkgs-2411.lib.nixosSystem {   # Ausnahme, siehe Eingang nixpkgs-2411
        system = "x86_64-linux";
        modules = [
          ./hosts/timo/hardware-configuration.nix
          ./hosts/timo/default.nix
          ./modules/base.nix
          ./modules/docker.nix
          ./modules/watchtower.nix
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
          ./hosts/eli/netz.nix
          ./modules/base.nix
          ./modules/docker.nix
        ];
      };

      # Der zweite Strato-Server, neu aufgesetzt im November 2026. Ohne
      # traefik.nix und watchtower.nix: Caddy bleibt als Container (die
      # Karten-Domains haengen an Zertifikaten ueber INWX), und die
      # Dienste hier haben Zustand, den ein unbeaufsichtigtes Image-Update
      # beschaedigen kann.
      anton = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs.unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
        modules = [
          ./hosts/anton/hardware-configuration.nix
          ./hosts/anton/default.nix
          ./hosts/anton/netz.nix
          ./hosts/anton/dienste.nix
          ./modules/base.nix
          ./modules/docker.nix
        ];
      };
    };
  };
}
