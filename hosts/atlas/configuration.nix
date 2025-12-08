# Atlas - media server (*arr stack, sabnzbd)
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/vm-config.nix
    ../../modules/vm-hardware-config.nix
    ../../modules/media-server.nix
    ../../modules/nfs-media.nix
    ../../modules/vpn.nix
    ../../modules/vpn-sabnzbd.nix
  ];

  networking.hostName = "atlas";
}
