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
      # Antons Session-Sync, dasselbe Muster. Ein Schluessel ohne
      # Beruehrungszwang, weil ein Timer keinen Finger hat.
      #
      # Bis zum 21.09.2026 lief sync-to-eli.sh ueber Antons Nitrokey. Alle
      # 15 Minuten, 116 Projektordner, je ein eigenes ssh - und jedes
      # wollte eine Beruehrung. 175 Anfragen in sieben Tagen, keine
      # beantwortet, kein Byte uebertragen. Automatisierung und
      # Anwesenheitspflicht schliessen einander aus; der Hardwareschluessel
      # bleibt fuer root und fuer Zugriffe, die tief ins System reichen.
      "command=\"/etc/ssh/rsync-anton.sh\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/v/HVgj7HLWdLtg6AbSMda+4UrBjDYAr+G0gVxbBRh anton-session-sync"
      # Und einer fuer die Codex-Sitzungen. Zwei Schluessel statt einem
      # mit weiterem Wurzelverzeichnis: ein Schluessel auf
      # /home/eli/geist/archive duerfte auch in Timos Verzeichnis
      # schreiben. Diese Grenze ist der Grund, warum es die Wrapper
      # ueberhaupt gibt.
      "command=\"/etc/ssh/rsync-codex.sh\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID0BtWdgxZpt9zakBfEpZuVXfMABYtnfxMphTIfskrmY anton-codex-sync"
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

  # Antons Wrapper. Dieselben zwei Richtungen wie bei Timo, nur ein
  # anderes Zielverzeichnis:
  #
  #   Pull  Backups holen aus /home/eli/offsite             (nur lesen)
  #   Push  Sessions ins Archiv /home/eli/geist/archive/anton (nur schreiben)
  #
  # Bewusst eine zweite Datei statt eines gemeinsamen, parametrisierten
  # Wrappers: Timos Zugang war fuenf Monate lang kaputt und ist erst am
  # 20.09.2026 wieder geprueft worden. Ihn anzufassen, waehrend er
  # nachweislich traegt, waere das falsche Risiko. Wer die beiden das
  # naechste Mal ohnehin anfasst, sollte sie zu einem Wrapper mit
  # Nutzerargument zusammenlegen.
  environment.etc."ssh/rsync-anton.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      case "$SSH_ORIGINAL_COMMAND" in
          "rsync --server --sender "*)
              exec ${pkgs.rrsync}/bin/rrsync -ro /home/eli/offsite
              ;;
          "rsync --server "*)
              exec ${pkgs.rrsync}/bin/rrsync -wo /home/eli/geist/archive/anton
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

  # Die Codex-Sitzungen kommen vom selben Rechner, gehoeren im Archiv
  # aber in ein eigenes Verzeichnis - serve.py fuehrt anton, timo und
  # codex als getrennte Nutzer. Nur schreiben, kein Lesen: Backups holt
  # der anton-Schluessel.
  environment.etc."ssh/rsync-codex.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      case "$SSH_ORIGINAL_COMMAND" in
          "rsync --server "*)
              exec ${pkgs.rrsync}/bin/rrsync -wo /home/eli/geist/archive/codex
              ;;
          *)
              echo "Nur rsync zum Senden erlaubt."
              echo "  rsync -av ./sessions/ eli@<host>:"
              exit 1
              ;;
      esac
    '';
  };

  # /etc/nixos/configuration.nix bricht mit dem richtigen Befehl ab.
  # Vorher lag dort die nixos-infect-Ausgabe vom 19.09.2026, und ein
  # schlichtes `nixos-rebuild switch` haette daraus gebaut. Warum kein
  # Wrapper-Flake: siehe etc-nixos/configuration.nix.
  #
  # Die Datei ersetzt die alte beim naechsten Rebuild (rename ueber die
  # bestehende Datei). Die uebrigen Reste von nixos-infect bleiben
  # liegen, bis sie von Hand weggeraeumt sind, siehe README; gebaut wird
  # aus ihnen nicht mehr, weil configuration.nix sie nicht importiert.
  environment.etc."nixos/configuration.nix".source = ./etc-nixos/configuration.nix;

  system.stateVersion = "24.11";
}
