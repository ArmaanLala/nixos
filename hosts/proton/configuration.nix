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

  networking.hostName = "proton";

  system.stateVersion = "25.05";
}
