# Lenix - Physical machine with Immich and Jellyfin
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/nfs.nix
    ../../modules/jellyfin.nix
    ../../modules/immich.nix
  ];

  networking.hostName = "lenix";

  nfsMounts = {
    "/mnt/immich" = "10.0.0.160:/mnt/wdblue/immich";
    "/mnt/media" = "10.0.0.160:/mnt/wdblue/arr";
  };

  # Override common.nix bootloader - lenix uses GRUB on /dev/sda (legacy BIOS)
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  system.stateVersion = "25.11";
}
