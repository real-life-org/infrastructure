# Platzhalter bis zur Neuinstallation. Danach die Datei von nixos-infect
# (/etc/nixos/hardware-configuration.nix) uebernehmen und pruefen:
#
#   grep -E " / | /boot" /proc/mounts     jede Partition muss hier stehen
#   ls /sys/firmware/efi                  vorhanden = UEFI, sonst BIOS
#
# Unter Ubuntu (vor der Neuinstallation) startete der Server per BIOS:
# GRUB auf /dev/vda, BIOS-Boot-Partition vda14, die eingehaengte
# EFI-Partition vda15 war ungenutzt, /boot lag auf der Wurzel (vda1).
# Ob das neue Image genauso aufgeteilt ist, steht erst danach fest.
{ modulesPath, ... }:
let
  wurzel = "NACH-NEUINSTALLATION-EINTRAGEN";   # /dev/disk/by-uuid/...
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  assertions = [{
    assertion = builtins.match "/dev/disk/by-uuid/.*" wurzel != null;
    message = "hosts/anton/hardware-configuration.nix: Werte von nixos-infect uebernehmen.";
  }];

  boot.loader.grub.device = "/dev/vda";

  fileSystems."/" = { device = wurzel; fsType = "ext4"; };

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" "sd_mod" ];
  swapDevices = [ ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
