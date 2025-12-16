# Atlas - unified media server (*arr stack, jellyfin, sabnzbd)
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/auto-upgrade.nix
    ../../modules/vm-config.nix
    ../../modules/vm-hardware-config.nix
    ../../modules/media-server.nix
    ../../modules/jellyfin.nix
    ../../modules/nfs.nix
    ../../modules/vpn.nix
    ../../modules/vpn-sabnzbd.nix
  ];

  networking.hostName = "atlas";

  nfsMounts = {
    "/mnt/buzz" = "10.0.0.160:/mnt/wdblue/buzzer";
    "/mnt/tforce" = "10.0.0.250:/mnt/tforce";
  };

  system.stateVersion = "25.05";
}
