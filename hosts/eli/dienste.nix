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

    # docker compose braucht das compose-Plugin, nicht nur den Client.
    path = with pkgs; [ docker docker-compose ];

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

    # systemd startet mit einem minimalen PATH, nicht mit dem einer
    # Anmeldung. Als cron-Job des Nutzers lief das Skript mit dessen
    # Umgebung; hier muss jedes Programm ausdruecklich dastehen, sonst
    # bricht der Lauf an der ersten Zeile ab, die eins davon braucht.
    #
    # Was das Skript benutzt: docker (Export im Container), sqlite3
    # (konsistente Kopien), gpg (verschluesseln), tar und gzip (packen),
    # git (Gedaechtnis-Repo pflegen), openssh (dessen Push), python3
    # (INDEX.json), dazu die ueblichen Werkzeuge aus coreutils,
    # findutils und gnugrep.
    path = with pkgs; [
      bash
      docker
      docker-compose
      sqlite
      gnupg
      gnutar
      gzip
      git
      openssh
      python3
      coreutils
      findutils
      gnugrep
      gnused
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "eli";
      # Ausdruecklich bash: das Skript nutzt "set -o pipefail", das
      # die POSIX-Shell nicht kennt. Und /bin/bash gibt es auf NixOS
      # nicht, der Shebang des Skripts liefe also ins Leere.
      ExecStart = "${pkgs.bash}/bin/bash /home/eli/backup-tool/eli-backup.sh";
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

  # Mail: Eli hat eine eigene Adresse unter eli.utopia-lab.org (Maddy,
  # Container eli-mail). Nach aussen offen ist nur Port 25, ueber den
  # andere Mailserver einliefern. Senden und Lesen (465, 587, 143, 993)
  # laufen nur im Docker-Netz: Elis eigener Code erreicht Maddy dort, und
  # niemand liest das Postfach mit einem Mailprogramm von aussen.
  # Entscheidung Eli und Anton, 26.11.2026. Die Ports muessen auch in der
  # Compose-Datei (eli-geist/geist) fehlen, sonst oeffnet Docker sie an
  # dieser Firewall vorbei.
  networking.firewall.allowedTCPPorts = [
    25    # SMTP, eingehend
  ];
}
