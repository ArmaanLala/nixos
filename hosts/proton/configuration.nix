# Proton - Jellyfin media server
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/auto-upgrade.nix
    ../../modules/vm-config.nix
    ../../modules/nfs-buzz.nix
    ../../modules/nfs-tforce.nix
    ../../modules/jellyfin.nix
    ../../modules/vpn.nix
    ../../modules/vpn-sabnzbd.nix
  ];

  networking.hostName = "proton";

  system.stateVersion = "25.05";
}
