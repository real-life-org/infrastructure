# Elis Server

Elis eigener Server: hier laufen ihre Dienste, hier liegt ihr Gedächtnis.
Beschrieben, damit ihm beim Ordnen und Weiterentwickeln geholfen werden
kann, ohne dass jemand sich erst auf dem Server umsehen muss.

## Was hier beschrieben ist

| Datei | Inhalt |
|---|---|
| `default.nix` | Rechnername, alle SSH-Zugänge, Timos eingeschränkter Wrapper |
| `dienste.nix` | Start des Container-Stapels, tägliches Backup, Mail-Ports |
| `hardware-configuration.nix` | **Platzhalter**, siehe unten |

Ohne `traefik.nix`: Eli hat ihren eigenen Caddy als Container, mit
Zertifikaten, die seit Monaten laufen. Auf Traefik umzustellen wäre eine
zweite Änderung während eines Umzugs.

## Was hier noch nicht beschrieben ist

**Die zehn Container selbst.** Sie stehen weiter in
`/home/eli/geist/docker-compose.yml` im Repo `eli-geist/geist`. Dieser
Schritt bringt Eli auf eine beschreibbare Grundlage; die Container
einzeln nach Nix zu übersetzen ist ein zweiter Schritt, Dienst für
Dienst.

**Die Geheimnisse.** Heute eine `.env` und ein `secrets/`-Verzeichnis im
Dateisystem. Auf dem Zielsystem gäbe es sops-nix. Das ist eine eigene
Entscheidung, weil davon abhängt, wer an Elis Zugänge kommt.

## Vor dem Umzug

Die Hardware-Beschreibung ist ein Platzhalter, und das ist Absicht: eine
geratene Datenträger-Kennung macht den Server unstartbar. Ein
vollständiger Build scheitert deshalb heute mit

    The 'fileSystems' option does not specify your root file system.

Das ist die richtige Antwort, solange der Platzhalter steht.

Ablauf:

1. frisches Backup, geprüft (nicht nur erzeugt)
2. `nixos-infect` läuft und legt `/etc/nixos/hardware-configuration.nix` an
3. diese Datei von dort übernehmen, gegen die Werte in der
   Platzhalter-Datei prüfen, erst dann einchecken
4. `nixos-rebuild switch --flake github:real-life-org/infrastructure#eli`

Besonderheit gegenüber timo: Elis Adresse hat eine **/32-Maske**, das
Gateway liegt außerhalb des eigenen Subnetzes und braucht eine eigene
Route. `nixos-infect` erzeugt die normalerweise richtig — prüfen, bevor
neu gestartet wird, sonst ist der Server nach dem Neustart nicht
erreichbar.

## Was geprüft ist

Stand 19.09.2026, mit `nix eval` gegen diese Dateien:

- die Konfiguration wertet aus, Rechnername `eli`
- Firewall öffnet 22, 25, 80, 143, 443, 465, 587, 993
- alle vier SSH-Zugänge landen in der Liste, Timos mit seinem festen Kommando
- `rrsync` löst auf ein vorhandenes Paket auf (3.4.1)
- ein vollständiger Build scheitert am Hardware-Platzhalter, wie er soll
