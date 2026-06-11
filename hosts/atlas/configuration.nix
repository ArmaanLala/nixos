# Atlas - unified media server (*arr stack, sabnzbd)
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/vm.nix
    ../../modules/media-server.nix
    ../../modules/nfs.nix
    ../../modules/vpn.nix
    ../../modules/vpn-sabnzbd.nix
  ];

  networking.hostName = "atlas";

  nfsMounts = {
    "/mnt/buzz" = "truenas:/mnt/wdblue/phub";
    "/mnt/media" = "truenas:/mnt/wdblue/arr";
  };

  system.stateVersion = "25.05";
}
