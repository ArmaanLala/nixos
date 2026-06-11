# Proton - Jellyfin media server
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/vm.nix
    ../../modules/jellyfin.nix
  ];

  # Use own hardware-configuration.nix instead of generic VM hardware
  vm.useGenericHardware = false;

  nfsMounts = {
    "/mnt/buzz" = "truenas:/mnt/wdblue/phub";
    "/mnt/media" = "truenas:/mnt/wdblue/arr";
  };

  networking.hostName = "proton";

  system.stateVersion = "25.05";
}
