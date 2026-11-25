# Werte vom frisch installierten System (Ubuntu 26.04, 25.11.2026), nicht
# vom alten. Bei einer erneuten Neuinstallation aendern sie sich wieder.
#
# Die Neuinstallation hat den Boot-Modus gewechselt: das alte Ubuntu
# startete per BIOS, das neue Image per UEFI, mit eigener Boot-Partition
# (vda13) wie bei eli. Dort liegen grub.cfg und die NixOS-Kernel. Ohne
# den Eintrag fuer /boot ginge der erste Start noch gut, aber der naechste
# nixos-rebuild schriebe die Kernel nach /boot auf der Wurzel, waehrend
# GRUB sie auf vda13 sucht (siehe hosts/eli/README.md).
#
# Pruefen nach jeder Neuinstallation:
#   grep -E " / | /boot" /proc/mounts     jede Partition muss hier stehen
#   ls /sys/firmware/efi                  vorhanden = UEFI
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.loader = {
    efi.efiSysMountPoint = "/boot/efi";
    grub = {
      efiSupport = true;
      # Ohne eigenen Eintrag in der Firmware: der Bootloader liegt als
      # EFI/BOOT/BOOTX64.EFI, wo jede Firmware ihn findet.
      efiInstallAsRemovable = true;
      device = "nodev";
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d8ce1de9-9053-44ed-a3d3-59a0c2067427";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/abdd7532-e2af-48d7-9e0f-6b0b87a017ef";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/33D1-4192";
    fsType = "vfat";
  };

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" "sd_mod" ];
  swapDevices = [ ];
  nixpkgs.hostPlatform = "x86_64-linux";
}
