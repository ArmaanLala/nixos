# Thinkpad - Lenovo ThinkPad X1 Yoga 7th Gen
{ pkgs, zen-browser, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/developer.nix
    ../../modules/steam.nix
  ];

  networking.hostName = "thinkpad";

  services.tailscale.enable = true;

  # Thinkpad-specific packages
  environment.systemPackages = with pkgs; [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    walker
  ];

  system.stateVersion = "25.11";
}
