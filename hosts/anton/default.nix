{ config, pkgs, ... }:
{
  # Der zweite Strato-Server (85.215.34.19). Bis November 2026 Ubuntu mit
  # vielen Einzeldiensten; danach frisch installiert und mit NixOS wie
  # timo und eli. Hier laufen die Karten (Utopia Map), Nextcloud,
  # HedgeDoc, Plausible, das F-Droid-Repo und der Signierdienst der Apps.
  networking.hostName = "anton";

  # Root nur ueber Antons Nitrokey, wie auf timo und eli.
  users.users.root.openssh.authorizedKeys.keys = import ../../nitrokeys.nix;

  # anton betreibt die Container. Wer in der docker-Gruppe ist, ist
  # faktisch root (der Daemon laeuft als root, ein Container kann /
  # einhaengen). Deshalb auch hier nur der Nitrokey, wie bei eli; der
  # RSA-Schluessel vom Ubuntu-System kommt nicht mit.
  users.users.anton = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = import ../../nitrokeys.nix;
  };

  # Watchtower nur fuer markierte Container: die WoT-Dienste und Karabirrdt
  # (Images aus der CI, oeffentlich auf ghcr.io). Nextcloud, Karte, HedgeDoc,
  # Plausible und der Mediator tragen das Label nicht und bleiben unberuehrt.
  realLife.watchtower = {
    nurMarkierte = true;
    registryAnmeldung = null;
  };

  system.stateVersion = "24.11";
}
