# Erzeugt von nixos-infect am 19.09.2026, danach von Hand ergaenzt.
#
# Was nixos-infect richtig erkannt hat: UEFI, die EFI-Partition, das
# Wurzel-Dateisystem, das qemu-guest-Profil.
#
# Was gefehlt hat: /boot. Der Server hat eine eigene Boot-Partition
# (vda13), und dort liegt alles Bootrelevante - grub.cfg und die
# NixOS-Kernel unter /boot/kernels. Ohne diesen Eintrag waere sie nach
# einem Neustart nicht eingehaengt: der erste Start ginge noch gut,
# weil GRUB weiss, wo seine Dateien liegen, aber der naechste
# nixos-rebuild schriebe die Kernel nach /boot auf der Wurzel, waehrend
# GRUB sie auf vda13 sucht. Dann bootet nichts mehr, und niemand
# wuesste warum.
#
# Die Werte stammen vom neu installierten System (Ubuntu 26.04,
# 19.09.2026), nicht vom alten. Bei einer erneuten Neuinstallation
# aendern sie sich wieder.

{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader = {
    efi.efiSysMountPoint = "/boot/efi";
    grub = {
      efiSupport = true;
      # Ohne eigenen Eintrag in der Firmware: der Bootloader liegt als
      # EFI/BOOT/BOOTX64.EFI, wo jede Firmware ihn findet. Bei Anbietern,
      # die keine dauerhaften Boot-Eintraege zulassen, ist das der
      # verlaessliche Weg.
      efiInstallAsRemovable = true;
      device = "nodev";
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/90d99162-58b5-439f-b459-a3d205abce11";
    fsType = "ext4";
  };

  # Von nixos-infect nicht erkannt, siehe oben.
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/a3b2debc-87ec-4b26-b394-ed18a26f093c";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/F76D-8173";
    fsType = "vfat";
  };

  # Die Platte ist /dev/vda, also virtio. Die virtio-Module kommen aus
  # qemu-guest.nix; die hier genannten stammen aus der Vorlage von
  # nixos-infect und schaden nicht.
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" "sd_mod" ];

  swapDevices = [ ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
