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
    "/mnt/buzz" = "10.0.0.160:/mnt/wdblue/buzzer";
    "/mnt/media" = "10.0.0.160:/mnt/wdblue/arr";
  };

  system.stateVersion = "25.05";
}
