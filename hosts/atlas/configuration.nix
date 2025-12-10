# Atlas - unified media server (*arr stack, jellyfin, sabnzbd)
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/vm-config.nix
    ../../modules/vm-hardware-config.nix
    ../../modules/media-server.nix
    ../../modules/jellyfin.nix
    ../../modules/nfs-buzz.nix
    ../../modules/nfs-tforce.nix
    ../../modules/vpn.nix
    ../../modules/vpn-sabnzbd.nix
  ];

  networking.hostName = "atlas";

  system.stateVersion = "25.05";
}
