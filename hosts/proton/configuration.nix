{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/common.nix
    ../../modules/hardware/nfs.nix
    ../../modules/services/vpn.nix
    ../../modules/hardware/vm-guest.nix
    ../../modules/services/jellyfin.nix
  ];

  nfs.shares = {
    buzz = "phub";
    media = "arr";
  };

  networking.hostName = "proton";

  system.stateVersion = "25.05";
}
