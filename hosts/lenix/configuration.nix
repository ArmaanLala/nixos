# Lenix - Physical machine with Immich and Jellyfin
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/nfs.nix
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

  # Jellyfin (inlined)
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Immich (inlined)
  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;
    host = "0.0.0.0";
    mediaLocation = "/mnt/immich/media";
  };
  systemd.tmpfiles.rules = [
    "d /mnt/immich/media 0755 immich immich -"
  ];

  system.stateVersion = "25.11";
}
