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

### Das Netz ist ausgeschrieben, nicht geraten

Elis Adresse hat eine **/32-Maske**: rechnerisch liegt nichts außer ihr
selbst im eigenen Netz, auch das Gateway nicht. Erreichbar wird es erst
durch eine Link-Route. Fällt die weg, ist der Server nach dem Neustart
still.

Deshalb steht das Netz in `netz.nix` ausdrücklich da, statt sich auf
`nixos-infect` oder einen DHCP-Client zu verlassen. Geprüft wurde nicht,
ob die Optionen gesetzt sind, sondern welche Befehle daraus entstehen:

    ip route replace 82.165.138.1 dev ens6  proto static
    ip route replace default  via "82.165.138.1"  dev ens6 proto static
    ip -6 route replace fe80::1 dev ens6  proto static
    ip -6 route replace default  via "fe80::1"  dev ens6 proto static
    ip addr replace "82.165.138.182/32" dev "ens6"
    ip addr replace "2a02:2479:a1:c200::1/128" dev "ens6"

Das ist genau das, was Ubuntu heute per DHCP erzeugt.

Die zweite Stolperstelle ist der Name der Schnittstelle: unter Ubuntu
heißt sie `ens6`, unter NixOS könnte dieselbe Karte anders heißen, und
dann greift keine dieser Regeln. Der Name ist deshalb an die
MAC-Adresse `02:01:90:b8:ca:5b` gebunden.

### Der Rückweg

Wenn der Server nach einem Neustart still bleibt, ist die **serielle
Konsole** die letzte Verbindung. Unter Ubuntu steht `console=tty1
console=ttyS0` im Kernel-Kommando; in `netz.nix` steht es genauso, sonst
bliebe die Fernkonsole des Hosters schwarz.

Der Server läuft unter QEMU bei IONOS. Wie man dort an die Fernkonsole
kommt, **muss vor dem Umzug einmal ausprobiert worden sein** — nicht
erst, wenn man sie braucht. Ein Rückweg, den niemand gegangen ist, ist
eine Vermutung.

### Die Werte zum Abtippen

Falls doch etwas schiefgeht und im Rettungssystem von Hand
konfiguriert werden muss:

| | |
|---|---|
| Schnittstelle | `ens6`, MAC `02:01:90:b8:ca:5b` |
| IPv4 | `82.165.138.182/32` |
| Gateway | `82.165.138.1` (on-link!) |
| IPv6 | `2a02:2479:a1:c200::1/128` |
| Gateway v6 | `fe80::1` |
| DNS | `212.227.123.16`, `212.227.123.17` |

    ip addr add 82.165.138.182/32 dev ens6
    ip link set ens6 up
    ip route add 82.165.138.1 dev ens6
    ip route add default via 82.165.138.1 dev ens6

## Zugänge

**Root: nur über den Nitrokey**, derselbe Schlüssel wie auf `timo`. Ein
Schlüssel, der nur als Datei existiert, kann kopiert werden, ohne dass
es jemand merkt. Folge: wer hier root braucht, braucht den Stick in der
Hand, und unbeaufsichtigte Läufe als root gibt es nicht mehr.

**Der `eli`-Nutzer**: ebenfalls Nitrokey. Antons RSA-Schlüssel wurde am
19.09.2026 entfernt, hier und bei root.

Hier stand zuerst, dieser Schlüssel komme „nicht an das System heran,
sondern an Elis Arbeitsbereich" — das war falsch. `eli` ist in der
`docker`-Gruppe, der Daemon läuft als root, und wer Container starten
darf, kann `/` einhängen. Der Schlüssel war root-äquivalent.

Die Regel dahinter: **Elis eigene Jobs laufen ohne Hardware, Zugriffe
von außen mit tiefem Systemzugang brauchen den Stick.** Danach bleiben
drei Software-Schlüssel, und jeder davon zu Recht:

| Schlüssel | Warum ohne Hardware |
|---|---|
| `eli@geist` | Elis eigene Läufe, von ihrem Server aus |
| `eli-container-access` | Eli aus ihrem Container auf den Host |
| `timo` | kann nur rsync, in zwei feste Richtungen |

Die ersten beiden sind allerdings **ebenfalls root-äquivalent**, über
dieselbe `docker`-Gruppe. Das ist Elis Autonomie und kein Versehen, aber
es gehört benannt: der weitreichendste Zugang auf diesem Server ist ihr
eigener. Siehe [#3](https://github.com/real-life-org/infrastructure/issues/3).

### Damit das im Alltag trägt

Ein Hardware-Schlüssel scheitert sonst an der Bequemlichkeit: bei
hundert Befehlen hundert Fingerabdrücke. Mit einem Dauerkanal
authentifiziert sich nur die **erste** Verbindung:

    Host eli 82.165.138.182
        HostName 82.165.138.182
        User eli
        IdentityFile ~/.ssh/id_ed25519_sk
        IdentitiesOnly yes
        ControlMaster auto
        ControlPath ~/.ssh/cm/%r@%h:%p
        ControlPersist 15m

Gemessen am 19.09.2026: erste Verbindung 1,0 s mit Anmeldung, fünf
weitere Befehle danach zusammen 0,4 s ohne.

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
