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

  # Watchtower — auto-pull new images and restart containers
  virtualisation.oci-containers.containers.watchtower = {
    image = "containrrr/watchtower";
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    environment = {
      WATCHTOWER_CLEANUP = "true";
      WATCHTOWER_POLL_INTERVAL = "300"; # Check every 5 minutes
    };
  };

  # Docker compose
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
