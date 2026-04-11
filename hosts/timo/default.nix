{ config, pkgs, ... }:
{
  networking.hostName = "timo";

  # Users
  users.users.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEZCBpqDTUBzarQd9Df/x2KWJMyV2/vsup1DvlcE99hxAAAABHNzaDo= mail@antontranelis.de"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsttgnEFLbNmin2V2TJ9Va9aleBwKTC226W76r2vSbD timo"
  ];

  system.stateVersion = "24.11";
}
