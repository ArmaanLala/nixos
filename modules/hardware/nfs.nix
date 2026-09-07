{ config, lib, ... }:
let
  mkNfsMount = device: {
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
  options.nfs = {
    server = lib.mkOption {
      type = lib.types.str;
      default = "truenas";
      description = ''
        Host used to reach the NAS. Roaming hosts set this to ts-truenas so the
        mounts resolve over the tailnet instead of the LAN.
      '';
    };

    shares = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        media = "arr";
        games = "games";
      };
      description = ''
        Shares under wdblue, as { mountName = shareName; }. The two names are
        deliberately separate because they do not always match: /mnt/media is
        wdblue/arr and /mnt/buzz is wdblue/phub.
      '';
    };
  };

  options.nfsMounts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Raw NFS mounts as { mountPoint = device; }";
  };

  config.fileSystems = lib.mkMerge [
    (lib.mapAttrs' (
      mountName: shareName:
      lib.nameValuePair "/mnt/${mountName}" (mkNfsMount "${config.nfs.server}:/mnt/wdblue/${shareName}")
    ) config.nfs.shares)

    (lib.mapAttrs (_: mkNfsMount) config.nfsMounts)
  ];
}
