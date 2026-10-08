{ config, lib, pkgs, ... }:
let
  cfg = config.realLife.traefik;
in
{
  options.realLife.traefik.extraNetworks = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "humhub_default" ];
    description = ''
      Docker-Netze von Compose-Stacks, die nicht im Netz bridge laufen.
      Traefik wird zusaetzlich an sie gehaengt, sonst erreicht er deren
      Container nicht (504 bzw. keine Antwort).
    '';
  };

  config = {
    # Traefik: Docker-native reverse proxy with auto-SSL
    virtualisation.oci-containers.containers.traefik = {
      image = "traefik:v3.3";
      cmd = [
        "--providers.docker=true"
        "--providers.docker.exposedbydefault=false"
        "--entrypoints.web.address=:80"
        "--entrypoints.web.http.redirections.entrypoint.to=websecure"
        "--entrypoints.websecure.address=:443"
        "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
        "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
      ];
      ports = [
        "80:80"
        "443:443"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "traefik_data:/data"
      ];
    };

    # docker-traefik.service legt den Container bei jedem Start neu an,
    # nur im Netz bridge. Die Netze haengen wir danach an, statt sie per
    # --network mitzugeben: fehlt eins (Stack mit `compose down` entfernt),
    # wuerde `docker run` scheitern und Traefik fuer alle Seiten ausfallen.
    # Der Timer faengt Netze auf, die ein `compose down && up` neu anlegt.
    systemd.services.traefik-netze = lib.mkIf (cfg.extraNetworks != [ ]) {
      description = "Traefik an die Netze der Compose-Stacks haengen";
      after = [ "docker-traefik.service" ];
      wantedBy = [ "docker-traefik.service" ];
      startAt = "*:0/5";
      path = [ config.virtualisation.docker.package ];
      serviceConfig.Type = "oneshot";
      script = ''
        for _ in $(seq 60); do
          [ "$(docker inspect -f '{{.State.Running}}' traefik 2>/dev/null)" = true ] && break
          sleep 1
        done

        for netz in ${lib.escapeShellArgs cfg.extraNetworks}; do
          if ! docker network inspect "$netz" >/dev/null 2>&1; then
            echo "Netz $netz gibt es nicht, uebersprungen"
            continue
          fi
          if docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' traefik \
              | tr ' ' '\n' | grep -qx "$netz"; then
            continue
          fi
          echo "Haenge Traefik an $netz"
          docker network connect "$netz" traefik
        done
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
