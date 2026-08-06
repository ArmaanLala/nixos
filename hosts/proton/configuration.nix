# Proton - Jellyfin media server
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/common.nix
    ../../modules/hardware/nfs.nix
    # Guest integration only — proton has its own hardware-configuration.nix,
    # so it does not get hardware/vm-disks.nix.
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
