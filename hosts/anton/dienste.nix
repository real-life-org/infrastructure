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
  ];
}
