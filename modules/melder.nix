{ config, lib, pkgs, ... }:
let
  # Zugang zum Telegram-Bot (Elis Bot), von Hand abgelegt, nicht im Repo:
  #   /var/lib/secrets/melder.env  (0600 root)
  #     TELEGRAM_TOKEN=...
  #     TELEGRAM_CHAT=...
  # Fehlt die Datei, schreibt der Melder nur ins Journal.
  envDatei = "/var/lib/secrets/melder.env";
  host = config.networking.hostName;
  marke = "/var/lib/melder/letztes-update";

  senden = pkgs.writeShellScript "melder-senden" ''
    set -u
    text="$1"
    echo "$text"
    [ -r ${envDatei} ] || { echo "melder: ${envDatei} fehlt, nichts gesendet"; exit 0; }
    # shellcheck disable=SC1091
    . ${envDatei}
    # Die URL mit dem Token kommt ueber stdin (--config -), nicht als Argument:
    # Argumente sieht jeder Prozess in ps. printf ist eingebaut, kein eigener
    # Prozess.
    printf 'url = "https://api.telegram.org/bot%s/sendMessage"\n' "$TELEGRAM_TOKEN" \
      | ${pkgs.curl}/bin/curl -fsS --max-time 20 -o /dev/null --config - \
          --data-urlencode "chat_id=$TELEGRAM_CHAT" \
          --data-urlencode "text=$text" \
      || echo "melder: Senden fehlgeschlagen"
  '';
in
{
  # Ein Dienst, der fehlschlaegt, meldet sich. Bewusst nur Name und Ergebnis,
  # keine Logzeilen: die koennen Geheimnisse enthalten.
  systemd.services."melder@" = {
    description = "Meldung: %i fehlgeschlagen";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${senden} '${host}: Dienst %i ist fehlgeschlagen. journalctl -u %i'";
    };
  };

  # Das naechtliche Update meldet, wenn es scheitert. Elis Update ist zwei
  # Monate lang jede Nacht gescheitert, ohne dass es jemand bemerkt hat.
  # Nach jedem erfolgreichen Lauf eine Zeitmarke: daran misst die taegliche
  # Pruefung, ob das Update ueberfaellig ist, unabhaengig von Neustarts.
  systemd.services.nixos-upgrade = {
    unitConfig.OnFailure = [ "melder@%n.service" ];
    serviceConfig.ExecStartPost = "${pkgs.coreutils}/bin/touch ${marke}";
  };

  # Taeglich: fehlgeschlagene Dienste, knapper Platz, ueberfaelliges Update.
  systemd.services.melder-pruefung = {
    description = "Taegliche Pruefung mit Meldung";
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ coreutils gawk systemd ];
    script = ''
      befunde=""
      fehl=$(systemctl --failed --no-legend --plain | awk 'NF {printf "%s ", $1}')
      [ -z "$fehl" ] || befunde="$befunde
      - fehlgeschlagen: $fehl"
      belegt=$(df --output=pcent / | tail -1 | tr -dc '0-9')
      [ "$belegt" -lt 85 ] || befunde="$befunde
      - Platte / zu $belegt % belegt"
      ergebnis=$(systemctl show nixos-upgrade.service -p Result --value)
      [ "$ergebnis" = success ] || befunde="$befunde
      - letztes naechtliches Update: $ergebnis"
      if [ ! -e ${marke} ]; then
        befunde="$befunde
      - noch kein erfolgreiches naechtliches Update vermerkt"
      elif [ $(( $(date +%s) - $(stat -c %Y ${marke}) )) -gt $((3 * 86400)) ]; then
        befunde="$befunde
      - letztes erfolgreiches Update vor mehr als 3 Tagen ($(date -r ${marke} '+%d.%m. %H:%M'))"
      fi
      [ -z "$befunde" ] && { echo "alles in Ordnung"; exit 0; }
      ${senden} "${host}:$befunde"
    '';
  };
  systemd.timers.melder-pruefung = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "07:30";
      Persistent = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/secrets 0700 root root -"
    "d /var/lib/melder 0755 root root -"
  ];
}
