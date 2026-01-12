# Thinkpad - Lenovo ThinkPad X1 Yoga 7th Gen
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/dev.nix
    ../../modules/gaming.nix
    ../../modules/nfs.nix
  ];

  nfsMounts = {
    "/mnt/media" = "ts-truenas:/mnt/wdblue/arr";
    "/mnt/games" = "ts-truenas:/mnt/wdblue/games";
  };

  networking.hostName = "thinkpad";
  time.timeZone = "America/New_York";

  # Fingerprint reader
  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  # Thinkpad-specific packages
  environment.systemPackages = with pkgs; [
    firefox
    thinkfan
  ];

  system.stateVersion = "25.11";
}
