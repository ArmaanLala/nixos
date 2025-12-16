# Lenix - Physical machine
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/auto-upgrade.nix
    ../../modules/immich.nix
    ../../modules/nfs.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "lenix";

  nfsMounts = {
    "/mnt/immich" = "10.0.0.160:/mnt/wdblue/immich";
  };

  # Override common.nix bootloader - lenix uses GRUB on /dev/sda
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  services.tailscale.enable = true;

  system.stateVersion = "25.11";
}
