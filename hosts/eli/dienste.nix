{ config, pkgs, ... }:
{
  # Elis Dienste laufen als Container, beschrieben in
  # /home/eli/geist/docker-compose.yml im Repo eli-geist/geist.
  #
  # Warum nicht virtualisation.oci-containers: zehn Dienste mit
  # Volumes, eigenem Netz und einer gemeinsamen .env einzeln nach Nix zu
  # uebersetzen ist ein zweiter grosser Schritt. Dieser hier bringt
  # Eli erst einmal auf eine beschreibbare Grundlage. Das Uebersetzen
  # der Container kommt danach, Dienst fuer Dienst.
  #
  # Was dieser Block leistet: der Stapel startet beim Hochfahren, ohne
  # dass jemand sich anmeldet, und er ist an einer Stelle beschrieben.

  systemd.services.eli-stack = {
    description = "Elis Dienste (docker compose)";
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/home/eli/geist";
      User = "eli";
      ExecStart = "${pkgs.docker}/bin/docker compose up -d --remove-orphans";
      ExecStop = "${pkgs.docker}/bin/docker compose stop";
      TimeoutStartSec = "600";
    };
  };

  # Elis Backup. Zwei Pakete: ein offenes mit den gemeinsamen Raeumen
  # fuer Timo, ein verschluesseltes mit allem fuer Anton. Das Skript
  # liegt im Repo eli-geist/geist unter backup-tool/ und prueft sich
  # selbst; es bricht ab, wenn der Export nicht vollstaendig ist oder
  # ein als sensibel markiertes Blatt ins offene Paket geraten waere.
  systemd.services.eli-backup = {
    description = "Elis Backup";
    after = [ "eli-stack.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "eli";
      ExecStart = "/home/eli/backup-tool/eli-backup.sh";
      TimeoutStartSec = "3600";
    };
  };

  systemd.timers.eli-backup = {
    description = "Elis Backup, taeglich";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "03:15";
      Persistent = true;   # nachholen, wenn der Server zu der Zeit aus war
    };
  };

  # Ports. Ueber die drei aus modules/base.nix hinaus braucht Eli die
  # Mail-Ports: sie hat eine eigene Adresse unter eli.utopia-lab.org und
  # kann darueber empfangen und antworten. Der Dienst ist zurzeit
  # ungenutzt, aber Teil des Entwurfs und sauber konfiguriert (Port 25
  # weist fremde Empfaenger ab, 587 verlangt Anmeldung).
  networking.firewall.allowedTCPPorts = [
    25    # SMTP, eingehend
    143   # IMAP
    465   # SMTPS
    587   # Submission
    993   # IMAPS
  ];
}
