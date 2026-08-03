{ config, pkgs, ... }:
{
  networking.hostName = "timo";

  # Admin: Anton (root access via Nitrokey)
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEOKw84pd96hpzCtWeuf3/2pJZ1Ue9Zq1O8mkVh75kNVAAAABHNzaDo= mail@antontranelis.de"
  ];

  # Timo: Docker-Rechte, kein sudo
  users.users.timo = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsttgnEFLbNmin2V2TJ9Va9aleBwKTC226W76r2vSbD timo"
    ];
  };

  system.stateVersion = "24.11";
}
