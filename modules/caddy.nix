{ config, pkgs, ... }:
{
  services.caddy = {
    enable = true;
  };

  # Caddy needs these ports open (already in base.nix, but explicit)
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
