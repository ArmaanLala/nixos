# Thinkpad - Lenovo ThinkPad X1 Yoga 7th Gen
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/common.nix
    ../../modules/roles/desktop.nix
    ../../modules/roles/dev.nix
    ../../modules/roles/gaming.nix
    ../../modules/hardware/nfs.nix
  ];

  # Roaming laptop — NAS over the tailnet.
  nfs.server = "ts-truenas";
  nfs.shares = {
    media = "arr";
    games = "games";
    manga = "manga";
  };

  networking.hostName = "thinkpad";

  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  environment.systemPackages = with pkgs; [
    thinkfan
  ];

  system.stateVersion = "25.11";
}
