# NFS buzz mount configuration
{ ... }:

{
  fileSystems."/mnt/buzz" = {
    device = "10.0.0.160:/mnt/wdblue/buzzer";
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
