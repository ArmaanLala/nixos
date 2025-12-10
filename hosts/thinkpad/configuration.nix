# Thinkpad - Lenovo ThinkPad X1 Yoga 7th Gen
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "thinkpad";

  system.stateVersion = "25.11";
}
