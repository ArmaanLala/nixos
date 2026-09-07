{ ... }:

{
  imports = [
    ../../modules/core/common.nix
    ../../modules/hardware/nfs.nix
    ../../modules/hardware/vm-guest.nix
    ../../modules/hardware/vm-disks.nix
    ../../modules/roles/media-server.nix
    ../../modules/services/vpn.nix
  ];

  networking.hostName = "atlas";

  nfs.shares = {
    buzz = "phub";
    media = "arr";
  };

  system.stateVersion = "25.05";
}
