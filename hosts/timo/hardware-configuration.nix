{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  # /boot ist die eigene Boot-Partition vda16 (ext4, Label BOOT), von der
  # GRUB die Kernel laedt: BOOT_IMAGE=(hd0,gpt16)/kernels/... Sie stand nie
  # in dieser Datei. Bis nixos-24.11 hing systemd-gpt-auto sie still von
  # selbst ein. Ab 26.05 haelt gpt-auto sie fuer eine FAT-Partition und
  # scheitert ("Can't find a valid FAT filesystem"); der automount-
  # Platzhalter auf /boot liess dazu dbus-broker scheitern, und Docker blieb
  # ohne D-Bus in "activating" (26.11.2026). Haette ein Rebuild danach die
  # Kernel nach /boot auf der Wurzel geschrieben, haette GRUB sie nicht
  # gefunden. Also ausdruecklich eintragen, wie bei eli, und gpt-auto aus.
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/419169ed-e354-47f5-9c4a-a6a4f1a382fa";
    fsType = "ext4";
  };
  boot.kernelParams = [ "systemd.gpt_auto=0" ];
}
