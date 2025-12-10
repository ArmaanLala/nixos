# Thinkpad - Lenovo ThinkPad X1 Yoga 7th Gen
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/desktop.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "thinkpad";

  services.tailscale.enable = true;

  system.stateVersion = "25.11";
}
