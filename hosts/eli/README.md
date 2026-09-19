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

Ohne `watchtower.nix`: automatische Image-Updates passen zu
zustandslosen Diensten, nicht zu Elis Bestand. Chroma, Neo4j und der
Mailserver tragen Daten, deren Format sich zwischen zwei Fassungen
ändern kann. Ein Beispiel aus dem eigenen Bestand: Chroma 1.0.0 wertet
die Authentifizierungs-Variablen nicht mehr aus, die früher wirkten —
der Dienst lief weiter und war sieben Monate ungeschützt, ohne dass
etwas ausfiel. Watchtower hätte genau so ein Update eingespielt, alle
30 Sekunden auf der Suche danach.

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

## Zugänge

**Root: nur über den Nitrokey**, derselbe Schlüssel wie auf `timo`. Ein
Schlüssel, der nur als Datei existiert, kann kopiert werden, ohne dass
es jemand merkt. Folge: wer hier root braucht, braucht den Stick in der
Hand, und unbeaufsichtigte Läufe als root gibt es nicht mehr.

**Der `eli`-Nutzer** hat den Nitrokey ebenfalls, behält daneben aber
vorerst Antons RSA-Schlüssel, damit unbeaufsichtigtes Arbeiten möglich
bleibt.

**Dieser Schlüssel ist root-äquivalent.** Hier stand zuerst, er komme
„nicht an das System heran, sondern an Elis Arbeitsbereich" — das war
falsch. `eli` ist in der `docker`-Gruppe, der Docker-Daemon läuft als
root, und wer Container starten darf, kann `/` einhängen und ist root.

Die Umstellung auf den Nitrokey härtet also die **direkte**
Root-Anmeldung. Es gibt weiterhin einen zweiten Weg zu root, und der
braucht keine Hardware. Die `docker`-Gruppe einfach zu entfernen geht
nicht: Elis Dienste und ihr Backup brauchen sie.

Ob dieser Schlüssel als benannte, root-äquivalente Ausnahme bleibt oder
ob die Grenze technisch gezogen wird, hängt an
[#3](https://github.com/real-life-org/infrastructure/issues/3).

**Offen:** ein Backup-Schlüssel auf beiden Servern. Geht der Nitrokey
verloren, ist root sonst nur noch über das Rettungssystem des Hosters
erreichbar — im August 2026 ist genau das schon einmal passiert.

## Was geprüft ist

Stand 19.09.2026, mit `nix eval` gegen diese Dateien:

- die Konfiguration wertet aus, Rechnername `eli`
- Firewall öffnet 22, 25, 80, 143, 443, 465, 587, 993
- root hat genau einen Schlüssel, den Nitrokey (was den **direkten**
  Root-Zugang betrifft, siehe oben)
- Watchtower läuft auf diesem Host **nicht**: `oci-containers.containers`
  ist leer, während `timo` weiterhin `traefik` und `watchtower` hat
- die Backup-Unit bekommt bash, docker, sqlite, gnupg, tar, gzip, git,
  openssh, python3, coreutils, findutils, grep und sed in den PATH
- der `eli`-Nutzer hat fünf, Timos mit seinem festen Kommando
- `rrsync` löst auf ein vorhandenes Paket auf (3.4.1)
- ein vollständiger Build scheitert am Hardware-Platzhalter, wie er soll
