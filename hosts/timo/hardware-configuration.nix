{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  # Auf der Platte liegt noch eine Boot-Partition vom urspruenglichen
  # Ubuntu (vda16, ext4, Label BOOT), dazu eine EFI-Partition (vda15).
  # Gestartet wird per GRUB von /dev/vda, die Kernel liegen in /boot auf
  # der Wurzel. systemd (ab nixos-26.05) erkennt vda16 von selbst und
  # versucht, sie ueber /boot zu haengen. Gelaenge das, schriebe der
  # naechste Rebuild die Kernel dorthin, waehrend GRUB sie auf der Wurzel
  # sucht, und der Server startete nicht mehr (vgl. hosts/eli/README.md).
  # Am 26.11.2026 erlebt: das Einhaengen scheiterte, aber der automount-
  # Platzhalter auf /boot liess dbus-broker beim Aufbau seines
  # Namensraums scheitern ("/boot: No such device"); ohne D-Bus blieb
  # Docker in "activating" haengen.
  # Deshalb die automatische Partitionserkennung aus.
  boot.kernelParams = [ "systemd.gpt_auto=0" ];
}
