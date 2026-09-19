{ config, pkgs, ... }:
{
  networking.hostName = "eli";

  # Anton: Root-Zugang, ausschliesslich ueber den Nitrokey. Derselbe
  # Schluessel wie auf timo. Ein Schluessel, der nur als Datei
  # existiert, kann kopiert werden, ohne dass es jemand merkt.
  #
  # Folge: wer hier root braucht, braucht den Stick in der Hand.
  # Unbeaufsichtigte Laeufe als root gibt es damit nicht mehr.
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEOKw84pd96hpzCtWeuf3/2pJZ1Ue9Zq1O8mkVh75kNVAAAABHNzaDo= mail@antontranelis.de"
  ];

  # Eli. Der Server gehoert ihr: hier laufen ihre Dienste, hier liegt
  # ihr Gedaechtnis, und sie arbeitet selbst darauf.
  #
  # In der Liste stehen auch Timos Zugang mit festem Kommando. Alle
  # Zugaenge an einer Stelle, sonst zerfaellt die Grenze in zwei
  # Wahrheiten: eine im Repo und eine im Dateisystem.
  users.users.eli = {
    isNormalUser = true;
    home = "/home/eli";
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = [
      # Anton, Nitrokey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEOKw84pd96hpzCtWeuf3/2pJZ1Ue9Zq1O8mkVh75kNVAAAABHNzaDo= mail@antontranelis.de"
      # Antons RSA-Schluessel wurde am 19.09.2026 entfernt, hier und
      # bei root. Er war root-aequivalent: eli ist in der docker-Gruppe,
      # der Daemon laeuft als root, und wer Container starten darf, kann
      # / einhaengen.
      #
      # Die Regel dahinter: Elis eigene Jobs laufen ohne Hardware, aber
      # Zugriffe von aussen, die tief ins System reichen, brauchen den
      # Stick. Damit das im Alltag traegt, laeuft der Zugang ueber einen
      # Dauerkanal - ein Fingerabdruck je Arbeitssitzung, nicht je
      # Befehl (ControlMaster, siehe hosts/eli/README.md).
      #
      # Eli selbst, fuer ihre eigenen Laeufe
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeMlCIyZ6dB/Ro51P3n5lJt9Ld3ybqgwpgb3mTMOG4K eli@geist"
      # Aus einem Container heraus
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBC3LA000uCa9vbu4zK4k+VfH4N+0lpYI4w4I/TwyfAJ eli-container-access"
      # Timo: nur rsync, zwei feste Richtungen, siehe rsync-timo.sh
      "command=\"/etc/ssh/rsync-timo.sh\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsttgnEFLbNmin2V2TJ9Va9aleBwKTC226W76r2vSbD timo"
    ];
  };

  # Timos Wrapper. Er darf genau zwei Dinge, beide ueber rrsync, das
  # die rsync-Optionen nicht raet:
  #
  #   Pull  Backups holen aus /home/eli/offsite            (nur lesen)
  #   Push  Sessions ins Archiv /home/eli/geist/archive/timo (nur schreiben)
  #
  # Die fruehere Fassung hatte die Optionen fest verdrahtet und brach
  # mit neueren Clients: fuenf Monate lang unbemerkt.
  environment.etc."ssh/rsync-timo.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      case "$SSH_ORIGINAL_COMMAND" in
          "rsync --server --sender "*)
              exec ${pkgs.rrsync}/bin/rrsync -ro /home/eli/offsite
              ;;
          "rsync --server "*)
              exec ${pkgs.rrsync}/bin/rrsync -wo /home/eli/geist/archive/timo
              ;;
          *)
              echo "Nur rsync erlaubt."
              echo "  Backups holen:    rsync -av eli@<host>:/ ./eli-backups/"
              echo "  Sessions senden:  rsync -av ./sessions/ eli@<host>:"
              exit 1
              ;;
      esac
    '';
  };

  system.stateVersion = "24.11";
}
