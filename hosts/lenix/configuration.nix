# Lenix - Physical machine with Immich, Jellyfin and Paperless
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/common.nix
    ../../modules/hardware/nfs.nix
    ../../modules/services/jellyfin.nix
    ../../modules/services/immich.nix
    ../../modules/services/paperless.nix
  ];

  networking.hostName = "lenix";

  nfs.shares = {
    immich = "immich";
    media = "arr";
  };

  # Override common.nix bootloader - lenix uses GRUB on /dev/sda (legacy BIOS)
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  system.stateVersion = "25.11";
}
