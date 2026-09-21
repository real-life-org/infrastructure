{ config, pkgs, ... }:
{
  # Locale
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # SSH hardening
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    curl
    wget
  ];

  # Naechtlicher Rebuild aus diesem Repo, 04:40, ohne Neustart.
  #
  # Bis zum 21.09.2026 stand hier nur `enable = true`, ohne `flake`. Der
  # Dienst rief dann `nixos-rebuild switch --upgrade` auf, den Weg ueber
  # /etc/nixos - und ein aus dem Flake gebautes System hat kein
  # `nixos-config` im NIX_PATH (nixpkgs: misc/nixpkgs-flake.nix). Der
  # Lauf scheiterte jede Nacht mit "file 'nixos-config' was not found":
  # auf timo seit mindestens Juni 2026, auf eli seit der Installation.
  # Es gab nie ein automatisches Update. Die Ueberschrift hiess trotzdem
  # "Automatic security updates".
  #
  # Zwei Folgen, beide bewusst:
  #
  # 1. Ein Merge in dieses Repo ist ein Deploy auf jeden Host, am
  #    naechsten Morgen. Wer das fuer einen Host nicht will, setzt dort
  #    `system.autoUpgrade.enable = lib.mkForce false` und schreibt dazu,
  #    warum. Ohne mkForce stuende es gegen das `true` hier: Konflikt.
  #
  # 2. Sicherheitsupdates kommen NUR, wenn jemand flake.lock hebt.
  #    nixpkgs ist gepinnt; `--refresh` holt den aktuellen Stand des
  #    Repos, nicht von nixpkgs. Siehe Issue zur Lock-Pflege.
  system.autoUpgrade = {
    enable = true;
    flake = "github:real-life-org/infrastructure#${config.networking.hostName}";
    allowReboot = false;
  };

  # Swap
  zramSwap.enable = true;

  # Clean tmp
  boot.tmp.cleanOnBoot = true;
}
