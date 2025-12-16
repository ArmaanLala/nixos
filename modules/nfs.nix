# Consolidated NFS mount configuration
{ config, lib, ... }:
let
  mkNfsMount = _: device: {
    inherit device;
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "soft"
      "timeo=30"
      "retrans=2"
      "nfsvers=4.2"
      "_netdev"
    ];
  };
in
{
  options.nfsMounts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "NFS mounts as { mountPoint = device; }";
  };

  config.fileSystems = lib.mapAttrs mkNfsMount config.nfsMounts;
}
