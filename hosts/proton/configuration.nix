# Proton - Jellyfin media server
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/vm.nix
    ../../modules/nfs.nix
    ../../modules/vpn.nix
    ../../modules/vpn-sabnzbd.nix
  ];

  # Use own hardware-configuration.nix instead of generic VM hardware
  vm.useGenericHardware = false;

  networking.hostName = "proton";

  nfsMounts = {
    "/mnt/buzz" = "10.0.0.160:/mnt/wdblue/buzzer";
  };

  # Jellyfin (inlined)
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  system.stateVersion = "25.05";
}
