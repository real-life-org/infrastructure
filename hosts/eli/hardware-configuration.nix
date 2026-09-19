# Platzhalter.
#
# Diese Datei wird beim Umzug von nixos-infect erzeugt und muss die
# echten Werte des Servers tragen. Sie hier zu raten waere gefaehrlich:
# eine falsche Datenträger-Kennung macht den Server unstartbar.
#
# Beim Umzug:
#   1. nixos-infect laeuft und legt /etc/nixos/hardware-configuration.nix an
#   2. diese Datei wird von dort uebernommen und ersetzt den Platzhalter
#   3. erst danach ist "nixos-rebuild switch --flake ...#eli" moeglich
#
# Was wir vom Ubuntu-Stand wissen (Stand 19.09.2026), als Gegenprobe:
#
#   Datenträger  vda, 240 GB
#     vda1       239 GB   /
#     vda15      106 MB   /boot/efi
#     vda16      913 MB   /boot
#   Netz         ens6, 82.165.138.182/32
#                Die /32-Maske ist die Besonderheit: das Gateway liegt
#                ausserhalb des eigenen Subnetzes und braucht eine
#                eigene Route. nixos-infect erzeugt die normalerweise
#                richtig; danach unbedingt pruefen, bevor neu gestartet
#                wird.
#   CPU          4 Kerne
#   RAM          7,7 GB
#
# Wenn die erzeugte Datei davon abweicht, erst klaeren, nicht uebernehmen.

{ ... }:
{
}
