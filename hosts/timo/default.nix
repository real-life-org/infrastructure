{ config, pkgs, ... }:
{
  networking.hostName = "timo";

  # Admin: Anton (root access via Nitrokey)
  users.users.root.openssh.authorizedKeys.keys = import ../../nitrokeys.nix;

  # Timo: Docker-Rechte, kein sudo, kein Root-Login.
  #
  # Bewusste Ausnahme von der Nitrokey-Regel (modules/base.nix): Docker ist
  # fuer Timo elementar, es ist sein Server. Wer Docker bedient, ist faktisch
  # root; Timos Schluessel sind Dateien. Timo besorgt sich einen Nitrokey,
  # danach gilt die Regel auch hier (Entscheidung Anton, 26.11.2026).
  users.users.timo = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsttgnEFLbNmin2V2TJ9Va9aleBwKTC226W76r2vSbD timo"
      # Timos Laptop; lag bisher nur in ~timo/.ssh/authorized_keys
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILKuHKYmliVzypRoMiO5Jjzu+QvQoN8GSwERK+rEyRN9 timo-x1-carbon"
    ];
  };

  # Anton, non-root: runs the mediator stack (web-of-trust deploy/mediator)
  users.users.anton = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = import ../../nitrokeys.nix;
  };

  # Compose-Stacks ausserhalb von bridge: lichtung.ooo (HumHub), Redekreis
  # und der VTI-Mediator (web-of-trust deploy/mediator)
  realLife.traefik.extraNetworks = [ "humhub_default" "kreis" "mediator-edge" ];

  system.stateVersion = "24.11";
}
