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
  };

  # Automatische Image-Updates liegen in modules/watchtower.nix.
  # Getrennt, weil sie nicht zu jedem Host passen: bei
  # zustandsbehafteten Diensten koennen sie Daten kosten.

  # Docker compose
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
