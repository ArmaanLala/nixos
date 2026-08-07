{ ... }:

{
  services.immich = {
    enable = true;
    port = 2283;
    openFirewall = true;
    host = "0.0.0.0";
    mediaLocation = "/mnt/immich/media";
  };

  # mediaLocation is on an NFS automount. Delay immich, not tmpfiles-setup —
  # ordering tmpfiles after the mount cycles (tmpfiles → sysinit → basic →
  # NetworkManager-wait-online → mnt-immich.mount → tmpfiles) and systemd breaks
  # the cycle by dropping a job at random.
  systemd.services.immich-server = {
    after = [ "mnt-immich.mount" ];
    requires = [ "mnt-immich.mount" ];
  };
}
