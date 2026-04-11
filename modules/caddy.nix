{ config, pkgs, ... }:
{
  # Create caddy network on startup
  systemd.services.docker-network-caddy = {
    description = "Create Docker caddy network";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.docker}/bin/docker network create caddy || true";
    };
  };

  # caddy-docker-proxy: Caddy with Docker label-based auto-configuration
  virtualisation.oci-containers.containers.caddy-proxy = {
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
    extraOptions = [ "--network=caddy" ];
  };

  # Caddy needs these ports open
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
