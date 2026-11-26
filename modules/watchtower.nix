{ config, lib, pkgs, ... }:
let
  cfg = config.realLife.watchtower;
in
{
  # Watchtower — zieht neue Images und startet Container neu.
  #
  # Bewusst ein eigenes Modul und nicht Teil von docker.nix: automatische
  # Updates passen zu zustandslosen Diensten, die aus einer CI kommen.
  # Bei zustandsbehafteten Diensten koennen sie Daten kosten. Eine
  # Datenbank, die ihr Format zwischen zwei Fassungen aendert, wird hier
  # ohne Rueckfrage und ohne Backup ausgetauscht.
  #
  # Ein Beispiel aus dem eigenen Bestand: Chroma 1.0.0 wertet die
  # Authentifizierungs-Variablen nicht mehr aus, die frueher wirkten.
  # Der Dienst lief weiter und war sieben Monate lang ungeschuetzt, ohne
  # dass etwas ausfiel. Ein automatisches Update haette das eingespielt.
  #
  # Ohne nurMarkierte gilt: alle Container hier vertragen einen Austausch im
  # laufenden Betrieb. Mit nurMarkierte nur die mit dem Label
  # com.centurylinklabs.watchtower.enable=true.
  options.realLife.watchtower = {
    nurMarkierte = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Nur Container mit dem Label com.centurylinklabs.watchtower.enable=true
        aktualisieren (WATCHTOWER_LABEL_ENABLE). Fuer Hosts mit Datendiensten,
        die nicht still ausgetauscht werden duerfen.
      '';
    };
    registryAnmeldung = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/root/.docker/config.json";
      description = ''
        Docker-Anmeldedaten fuer private Images, nur lesend eingehaengt.
        null, wenn alle beobachteten Images oeffentlich sind (fehlt die Datei,
        legte Docker an ihrer Stelle ein Verzeichnis an).
      '';
    };
  };

  config.virtualisation.oci-containers.containers.watchtower = {
    # containrrr/watchtower ist seit Dezember 2025 archiviert und spricht
    # eine Docker-API, die Docker 29 nicht mehr annimmt. Der gepflegte Fork
    # von nicholas-fedor ist ein Ersatz mit denselben Variablen und
    # handelt die API-Version aus. Feste Version: Watchtower hat den
    # Docker-Socket, ein unbeaufsichtigter Wechsel seines Images waere
    # ein Wechsel dessen, der root hat.
    image = "nickfedor/watchtower:1.24.2";
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ]
      # nur lesend: Watchtower braucht die Anmeldedaten, nicht das Recht,
      # sie zu aendern (Review Astra, 26.11.2026)
      ++ lib.optional (cfg.registryAnmeldung != null) "${cfg.registryAnmeldung}:/config.json:ro";
    environment = {
      WATCHTOWER_CLEANUP = "true";
      WATCHTOWER_POLL_INTERVAL = "30";
    } // lib.optionalAttrs cfg.nurMarkierte {
      WATCHTOWER_LABEL_ENABLE = "true";
    };
  };
}
