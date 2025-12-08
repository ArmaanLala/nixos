# Proton - Jellyfin media server
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/vm-config.nix
    ../../modules/nfs-media.nix
    ../../modules/jellyfin.nix
    ../../modules/vpn.nix
    ../../modules/vpn-sabnzbd.nix
  ];

  networking.hostName = "proton";
}
