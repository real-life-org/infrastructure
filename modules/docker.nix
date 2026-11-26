{ config, pkgs, ... }:
{
  # Use Docker (not Podman) as backend for NixOS-managed containers
  virtualisation.oci-containers.backend = "docker";

  # Docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    # Container-Logs begrenzen: ohne Grenze waechst jede *-json.log ohne
    # Ende, bis die Platte voll ist. Gilt fuer Container, die nach der
    # Aenderung angelegt werden (compose up --force-recreate fuer alte).
    daemon.settings = {
      log-driver = "json-file";
      log-opts = {
        max-size = "20m";
        max-file = "5";
      };
    };
  };

  # Automatische Image-Updates liegen in modules/watchtower.nix.
  # Getrennt, weil sie nicht zu jedem Host passen: bei
  # zustandsbehafteten Diensten koennen sie Daten kosten.

  # Docker compose
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
