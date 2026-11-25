{ config, pkgs, ... }:
{
  # Der zweite Strato-Server (85.215.34.19). Bis November 2026 Ubuntu mit
  # vielen Einzeldiensten; danach frisch installiert und mit NixOS wie
  # timo und eli. Hier laufen die Karten (Utopia Map), Nextcloud,
  # HedgeDoc, Plausible, das F-Droid-Repo und der Signierdienst der Apps.
  networking.hostName = "anton";

  # Root nur ueber Antons Nitrokey, wie auf timo und eli.
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEOKw84pd96hpzCtWeuf3/2pJZ1Ue9Zq1O8mkVh75kNVAAAABHNzaDo= mail@antontranelis.de"
  ];

  # anton betreibt die Container. Wer in der docker-Gruppe ist, ist
  # faktisch root (der Daemon laeuft als root, ein Container kann /
  # einhaengen). Deshalb auch hier nur der Nitrokey, wie bei eli; der
  # RSA-Schluessel vom Ubuntu-System kommt nicht mit.
  users.users.anton = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEOKw84pd96hpzCtWeuf3/2pJZ1Ue9Zq1O8mkVh75kNVAAAABHNzaDo= mail@antontranelis.de"
    ];
  };

  system.stateVersion = "24.11";
}
