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

  # Opt out of common.nix's pinned pihole nameserver. This one roams, and
  # 10.0.0.222 is unreachable off-LAN -- every fresh lookup would block on it
  # until timeout before falling through. Plain "" beats the mkDefault there.
  networking.resolvconf.extraConfig = "";

  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  environment.systemPackages = with pkgs; [
    thinkfan
  ];

  system.stateVersion = "25.11";
}
