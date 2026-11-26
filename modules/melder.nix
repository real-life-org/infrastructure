{ config, lib, pkgs, ... }:
let
  # Zugang zum Telegram-Bot (Elis Bot), von Hand abgelegt, nicht im Repo:
  #   /var/lib/secrets/melder.env  (0600 root)
  #     TELEGRAM_TOKEN=...
  #     TELEGRAM_CHAT=...
  # Fehlt die Datei, schreibt der Melder nur ins Journal.
  envDatei = "/var/lib/secrets/melder.env";
  host = config.networking.hostName;

  senden = pkgs.writeShellScript "melder-senden" ''
    set -u
    text="$1"
    echo "$text"
    [ -r ${envDatei} ] || { echo "melder: ${envDatei} fehlt, nichts gesendet"; exit 0; }
    # shellcheck disable=SC1091
    . ${envDatei}
    ${pkgs.curl}/bin/curl -fsS --max-time 20 -o /dev/null \
      --data-urlencode "chat_id=$TELEGRAM_CHAT" \
      --data-urlencode "text=$text" \
      "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
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
  systemd.services.nixos-upgrade.unitConfig.OnFailure = [ "melder@%n.service" ];

  # Taeglich: fehlgeschlagene Dienste, knapper Platz, ueberfaelliges Update.
  systemd.services.melder-pruefung = {
    description = "Taegliche Pruefung mit Meldung";
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ coreutils gawk systemd ];
    script = ''
      befunde=""
      fehl=$(systemctl --failed --no-legend --plain | awk '{print $1}' | tr '\n' ' ')
      [ -z "$fehl" ] || befunde="$befunde
      - fehlgeschlagen: $fehl"
      belegt=$(df --output=pcent / | tail -1 | tr -dc '0-9')
      [ "$belegt" -lt 85 ] || befunde="$befunde
      - Platte / zu $belegt % belegt"
      zuletzt=$(systemctl show nixos-upgrade.service -p ExecMainExitTimestampMonotonic --value)
      ergebnis=$(systemctl show nixos-upgrade.service -p Result --value)
      jetzt=$(awk '{print int($1 * 1000000)}' /proc/uptime)
      # Nur pruefbar, wenn das Update seit dem Start schon lief
      if [ "''${zuletzt:-0}" -gt 0 ] && [ "$ergebnis" != success ]; then
        befunde="$befunde
      - letztes naechtliches Update: $ergebnis"
      fi
      if [ "$jetzt" -gt $((3 * 86400 * 1000000)) ] && [ "''${zuletzt:-0}" -eq 0 ]; then
        befunde="$befunde
      - naechtliches Update lief seit ueber 3 Tagen nicht"
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

  systemd.tmpfiles.rules = [ "d /var/lib/secrets 0700 root root -" ];
}
