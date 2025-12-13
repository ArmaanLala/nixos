# Thinkpad - Lenovo ThinkPad X1 Yoga 7th Gen
{ pkgs, zen-browser, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/developer.nix
    ../../modules/steam.nix
    ../../modules/stylix.nix
  ];

  networking.hostName = "thinkpad";
  time.timeZone = "America/New_York";

  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-vfs0090;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;
  # Thinkpad-specific packages
  environment.systemPackages = with pkgs; [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    thinkfan
  ];

  system.stateVersion = "25.11";
}
