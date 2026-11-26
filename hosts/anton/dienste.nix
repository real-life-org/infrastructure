{ config, pkgs, unstable, ... }:
{
  # Signierdienst der Apps (Repo real-life-org/wot-release, privat).
  #
  # Der Dienst selbst sind Docker-Container (Compose-Datei im Repo); dieser
  # Runner stoesst sie nur an. Er haengt ausschliesslich am privaten Repo:
  # an einem oeffentlichen koennte ein Fork-PR Code auf der Maschine
  # ausfuehren, auf der der F-Droid-Schluessel liegt. Die App-Repos schicken
  # nur ein repository_dispatch.
  #
  # Unter Ubuntu lief der Runner als Nutzerdienst von anton, aus einem
  # heruntergeladenen Archiv. Hier kommt er aus nixpkgs, mit eigenem
  # Systemnutzer. Wer Docker bedienen darf, ist faktisch root; der eigene
  # Nutzer trennt also nicht die Rechte, aber die Herkunft in Logs und
  # Prozessliste.
  users.users.wot-release = {
    isSystemUser = true;
    group = "wot-release";
    extraGroups = [ "docker" ];
  };
  users.groups.wot-release = { };

  services.github-runners.wot-release = {
    enable = true;
    # GitHub weist Runner unter einer Mindestversion ab (seit Februar 2026);
    # nixos-24.11 hat 2.325, abgewiesen mit 404. Deshalb aus nixos-unstable.
    # Das Modul schaltet das Selbst-Update ab: spaetestens 30 Tage nach jeder
    # neuen Runner-Version muss der Eingang nixpkgs-unstable in flake.lock
    # angehoben werden (nix flake update nixpkgs-unstable), sonst bekommt der
    # Runner keine Jobs mehr.
    package = unstable.github-runner;
    url = "https://github.com/real-life-org/wot-release";
    # Registrierungs-Token (eine Stunde gueltig), von Hand abgelegt:
    #   gh api -X POST repos/real-life-org/wot-release/actions/runners/registration-token --jq .token
    # Die Datei MUSS liegen bleiben: das Modul vergleicht sie bei jedem Start
    # mit seiner gespeicherten Kopie. Fehlt sie oder ist sie anders, gilt das
    # als neue Konfiguration, der Zustand wird geloescht und neu registriert
    # (mit einem abgelaufenen Token schlaegt das fehl).
    tokenFile = "/var/lib/secrets/wot-release-runner.token";
    name = "strato-neu";
    replace = true;            # der alte Eintrag gleichen Namens ist mit Ubuntu verschwunden
    extraLabels = [ "wot-release" ];
    user = "wot-release";
    group = "wot-release";

    extraPackages = with pkgs; [ docker gnugrep gnused findutils ];

    # Das Signer-Image ist privat: Anmeldung bei ghcr.io (klassisches Token,
    # read:packages) liegt in dieser config.json, lesbar nur fuer wot-release.
    extraEnvironment.DOCKER_CONFIG = "/var/lib/wot-release-docker";

    serviceOverrides = {
      # PrivateUsers bildet die docker-Gruppe nicht ab; ohne sie kein Zugriff
      # auf /run/docker.sock.
      PrivateUsers = false;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/secrets 0700 root root -"
    "d /var/lib/wot-release-docker 0700 wot-release wot-release -"
    # Lesbar fuer alle: Caddy haengt das Verzeichnis nur lesend ein.
    "d /srv/artifacts 0755 artifacts artifacts -"
  ];

  # Spiegel der Claude-Artefakte (Anton, 26.11.2026): Jede Seite, die
  # Anton ueber Claude veroeffentlicht, kommt per rsync hierher und wird
  # von Caddy statisch ausgeliefert. Der Schluessel liegt ohne Passphrase
  # auf Antons Laptop (ein Hook hat keinen Finger), darf deshalb nur
  # schreiben, nur in /srv/artifacts und nichts loeschen; -munge entschaerft
  # hochgeladene Symlinks, damit nichts ausserhalb ausgeliefert wird. Eigener
  # Nutzer ohne docker-Gruppe: ein gestohlener Schluessel legt Dateien ab,
  # mehr nicht.
  users.users.artifacts = {
    isSystemUser = true;
    group = "artifacts";
    # Das Home ist NICHT das Upload-Ziel. Laege es in /srv/artifacts, koennte
    # der Schluessel dort .bashrc oder .ssh/rc ablegen, und sshd bzw. Bash
    # werteten sie vor dem erzwungenen Kommando aus (rrsync(1), "Bash
    # security issue"). /var/empty gehoert root und ist fuer artifacts
    # nicht beschreibbar.
    home = "/var/empty";
    createHome = false;
    # sshd startet das erzwungene Kommando ueber die Login-Shell; mit
    # nologin (Vorgabe fuer Systemnutzer) liefe nichts.
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      # restrict schaltet alles ab, was nicht ausdruecklich erlaubt ist,
      # auch ~/.ssh/rc (no-user-rc).
      "restrict,command=\"/etc/ssh/rsync-artifacts.sh\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAQjwrkW7rO2r/Cr7csvirFr//em9w6McR6K0nGN8Yw artifact-mirror"
    ];
  };
  users.groups.artifacts = { };

  environment.etc."ssh/rsync-artifacts.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      case "$SSH_ORIGINAL_COMMAND" in
          "rsync --server --sender "*)
              echo "Nur schreiben erlaubt."
              exit 1
              ;;
          "rsync --server "*)
              exec ${pkgs.rrsync}/bin/rrsync -wo -no-del -munge /srv/artifacts
              ;;
          *)
              echo "Nur rsync erlaubt: rsync seite.html artifacts@<host>:"
              exit 1
              ;;
      esac
    '';
  };
}
