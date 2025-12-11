# Thinkpad - Lenovo ThinkPad X1 Yoga 7th Gen
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/developer.nix
  ];

  networking.hostName = "thinkpad";

  services.tailscale.enable = true;

  system.stateVersion = "25.11";
}
