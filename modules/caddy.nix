{ config, pkgs, ... }:
{
  # Disable NixOS Caddy service — we use caddy-docker-proxy instead
  services.caddy.enable = false;

  # caddy-docker-proxy: Caddy with Docker label-based auto-configuration
  virtualisation.oci-containers.containers.caddy = {
    image = "lucaslorentz/caddy-docker-proxy:2.9";
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "caddy_data:/data"
    ];
    environment = {
      CADDY_INGRESS_NETWORKS = "caddy";
    };
  };

  # Caddy needs these ports open
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
