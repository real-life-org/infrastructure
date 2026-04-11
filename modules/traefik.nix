{ config, pkgs, ... }:
{
  # Traefik: Docker-native reverse proxy with auto-SSL
  virtualisation.oci-containers.containers.traefik = {
    image = "traefik:v3.3";
    cmd = [
      "--providers.docker=true"
      "--providers.docker.exposedbydefault=false"
      "--entrypoints.web.address=:80"
      "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      "--entrypoints.websecure.address=:443"
      "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
    ];
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "traefik_data:/data"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
