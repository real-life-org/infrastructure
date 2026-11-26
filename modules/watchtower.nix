{ config, pkgs, ... }:
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
  # Wer dieses Modul importiert, sagt damit: alle Container hier
  # vertragen einen Austausch im laufenden Betrieb.
  virtualisation.oci-containers.containers.watchtower = {
    # containrrr/watchtower ist seit Dezember 2025 archiviert und spricht
    # eine Docker-API, die Docker 29 nicht mehr annimmt. Der gepflegte Fork
    # von nicholas-fedor ist ein Ersatz mit denselben Variablen und
    # handelt die API-Version aus. Feste Version: Watchtower hat den
    # Docker-Socket, ein unbeaufsichtigter Wechsel seines Images waere
    # ein Wechsel dessen, der root hat.
    image = "nickfedor/watchtower:1.24.2";
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "/root/.docker/config.json:/config.json"
    ];
    environment = {
      WATCHTOWER_CLEANUP = "true";
      WATCHTOWER_POLL_INTERVAL = "30";
    };
  };
}
