{ config, pkgs, lib, ... }:
let
  # Die MAC aendert sich bei der Neuinstallation (bei eli am 19.09.2026
  # erlebt). Erst nach der Neuinstallation ablesen und hier eintragen:
  #   ip link show ens6 | grep -o "link/ether [0-9a-f:]*"
  # Unter Ubuntu vor der Neuinstallation: 02:01:d9:44:60:0d.
  mac = "NACH-NEUINSTALLATION-EINTRAGEN";
in
{
  # Dasselbe Muster wie eli (siehe hosts/eli/netz.nix): eine /32-Adresse,
  # das Gateway liegt ausserhalb des eigenen Netzes und wird erst ueber
  # eine Link-Route erreichbar. Unter Ubuntu kam per DHCP:
  #
  #   ens6           85.215.34.19/32
  #   85.215.34.1    dev ens6  scope link
  #   default        via 85.215.34.1 dev ens6
  #   IPv6           2a02:2479:79:2d00::1/128, Router ueber fe80::1
  #
  # Faellt die Link-Route weg, ist der Server nach dem Neustart still.
  assertions = [{
    assertion = builtins.match "([0-9a-f]{2}:){5}[0-9a-f]{2}" mac != null;
    message = "hosts/anton/netz.nix: MAC nach der Neuinstallation eintragen.";
  }];

  networking = {
    useDHCP = false;
    usePredictableInterfaceNames = true;

    interfaces.ens6 = {
      ipv4.addresses = [{ address = "85.215.34.19"; prefixLength = 32; }];
      ipv4.routes = [{ address = "85.215.34.1"; prefixLength = 32; }];
      ipv6.addresses = [{ address = "2a02:2479:79:2d00::1"; prefixLength = 128; }];
    };

    defaultGateway = { address = "85.215.34.1"; interface = "ens6"; };
    defaultGateway6 = { address = "fe80::1"; interface = "ens6"; };

    # Die Resolver, zu denen Ubuntu per DHCP eigene Routen bekam.
    nameservers = [ "212.227.123.16" "212.227.123.17" ];
  };

  # Serielle Konsole wie unter Ubuntu; sie ist der Rueckweg, wenn das
  # Netz nach einem Neustart nicht kommt. Die zuletzt genannte Konsole
  # wird /dev/console.
  boot.kernelParams = [ "console=tty1" "console=ttyS0" ];

  systemd.network.links."10-ens6" = {
    matchConfig.MACAddress = mac;
    linkConfig.Name = "ens6";
  };
}
