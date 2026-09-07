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

  nfs.server = "ts-truenas";
  nfs.shares = {
    media = "arr";
    games = "games";
    manga = "manga";
  };

  networking.hostName = "thinkpad";

  networking.resolvconf.extraConfig = "";

  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  environment.systemPackages = with pkgs; [
    thinkfan
  ];

  system.stateVersion = "25.11";
}
