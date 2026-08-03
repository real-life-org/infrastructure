#!/bin/sh
# SSH-Zugang auf Timos NixOS-Server (h2980589) wiederherstellen.
# Im Strato-Rettungssystem ausfuehren. Traegt Antons GitHub-Keys
# in /root/.ssh/authorized_keys des installierten Systems ein.
set -e

echo "== Partitionen =="
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT

# Groesste Linux-Partition finden und mounten
mkdir -p /mnt
for dev in /dev/vda1 /dev/vda2 /dev/vda3 /dev/sda1 /dev/sda2; do
  [ -b "$dev" ] || continue
  if mount "$dev" /mnt 2>/dev/null; then
    if [ -d /mnt/etc/nixos ] || [ -d /mnt/root ]; then
      echo "== Gemountet: $dev =="
      break
    fi
    umount /mnt
  fi
done

if ! mountpoint -q /mnt; then
  echo "FEHLER: Keine Systempartition gefunden. Bitte manuell mounten (lsblk oben)."
  exit 1
fi

mkdir -p /mnt/root/.ssh
curl -fsSL https://github.com/antontranelis.keys > /mnt/root/.ssh/authorized_keys
chmod 700 /mnt/root/.ssh
chmod 600 /mnt/root/.ssh/authorized_keys

echo "== Eingetragene Keys =="
cat /mnt/root/.ssh/authorized_keys

umount /mnt
echo "== FERTIG. Jetzt im Strato-Panel das Rettungssystem stoppen und neu booten. =="
