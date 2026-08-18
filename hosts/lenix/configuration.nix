# Lenix - bare metal; Jellyfin, Immich, Paperless
{ pkgs, ... }:

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

  # Lenix is the always-on box on 10.0.0.0/24, so it's what wakes drapion after
  # hypridle suspends it. A magic packet is an L2 broadcast and cannot cross the
  # tailnet, so the sender has to live on the LAN rather than on a roaming host.
  #   wol -i 10.0.0.255 d8:43:ae:45:60:68
  environment.systemPackages = [ pkgs.wol ];

  # Legacy BIOS — GRUB on /dev/sda, not the systemd-boot default.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  system.stateVersion = "25.11";
}
