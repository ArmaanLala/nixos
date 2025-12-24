# Thinkpad - Lenovo ThinkPad X1 Yoga 7th Gen
{ pkgs, ... }:

let
  # Toggle: true = LAN (10.0.0.160), false = Tailscale (ts-truenas)
  useLocalNfs = false;
  nfsHost = if useLocalNfs then "10.0.0.160" else "ts-truenas";
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/roles/desktop-workstation.nix
    ../../modules/nfs.nix
  ];

  nfsMounts = {
    "/mnt/media" = "${nfsHost}:/mnt/wdblue/arr";
    "/mnt/games" = "${nfsHost}:/mnt/wdblue/games";
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
    desmume
    mgba
  ];

  system.stateVersion = "25.11";
}
