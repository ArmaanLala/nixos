# NFS tforce mount configuration
{ ... }:

{
  fileSystems."/mnt/tforce" = {
    device = "10.0.0.250:/mnt/tforce";
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
}
