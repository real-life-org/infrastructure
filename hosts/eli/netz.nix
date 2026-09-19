{ config, pkgs, lib, ... }:
{
  # Elis Netz, ausdruecklich statt geraten.
  #
  # Die Adresse hat eine /32-Maske: rechnerisch liegt nichts ausser ihr
  # selbst im eigenen Netz, auch das Gateway nicht. Erreichbar wird es
  # erst durch eine Link-Route, die sagt "diese eine Adresse ist direkt
  # am Kabel". Darauf setzt dann die Standard-Route auf.
  #
  # Unter Ubuntu kam das per DHCP von IONOS und sah so aus:
  #
  #   ens6           82.165.138.182/32
  #   82.165.138.1   dev ens6  scope link      <- diese Zeile ist alles
  #   default        via 82.165.138.1 dev ens6
  #
  # Faellt die Link-Route weg, ist der Server nach dem Neustart still.
  # Deshalb steht sie hier ausgeschrieben und nicht im Vertrauen darauf,
  # dass der DHCP-Client sie wieder richtig erzeugt.

  networking = {
    useDHCP = false;
    usePredictableInterfaceNames = true;

    interfaces.ens6 = {
      ipv4.addresses = [{
        address = "82.165.138.182";
        prefixLength = 32;
      }];

      # Das Gateway direkt am Kabel erreichbar machen. Ohne diesen
      # Eintrag scheitert die Standard-Route unten daran, dass
      # 82.165.138.1 in keinem bekannten Netz liegt.
      ipv4.routes = [{
        address = "82.165.138.1";
        prefixLength = 32;
      }];

      ipv6.addresses = [{
        address = "2a02:2479:a1:c200::1";
        prefixLength = 128;
      }];
    };

    defaultGateway = {
      address = "82.165.138.1";
      interface = "ens6";
    };

    # IPv6 laeuft ueber die Link-Local-Adresse des Routers, so wie es
    # unter Ubuntu per Router Advertisement ankam.
    defaultGateway6 = {
      address = "fe80::1";
      interface = "ens6";
    };

    nameservers = [
      "212.227.123.16"
      "212.227.123.17"
      "2001:8d8:fe:53:72ec::1"
      "2001:8d8:fe:53:72ec::2"
    ];
  };

  # Der Name der Schnittstelle ist die zweite Stolperstelle. Unter
  # Ubuntu heisst sie ens6; unter NixOS koennte dieselbe Karte anders
  # heissen, und dann greift keine der Regeln oben. Deshalb wird der
  # Name hier an die MAC-Adresse gebunden.
  systemd.network.links."10-ens6" = {
    matchConfig.MACAddress = "02:01:90:b8:ca:5b";
    linkConfig.Name = "ens6";
  };
}
