# Weed - media server (*arr stack, sabnzbd)
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/auto-upgrade.nix
    ../../modules/vm-config.nix
    ../../modules/vm-hardware-config.nix
    ../../modules/nfs-tforce.nix
    ../../modules/jellyfin.nix
  ];

  networking.hostName = "weed";

  system.stateVersion = "25.05";
}
