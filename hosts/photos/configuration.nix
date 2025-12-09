# Photos - photo management server (immich)
{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/vm-config.nix
    ../../modules/vm-hardware-config.nix
    # ../../modules/immich.nix
    ../../modules/nfs-immich.nix
  ];

  networking.hostName = "photos";

  system.stateVersion = "25.05";
}
